import AVFoundation
import Observation
import Accelerate

@Observable
final class AudioCaptureEngine: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private(set) var isCapturing = false

    // Store raw float audio for later conversion
    private var rawSamples: [Float] = []
    private var captureFormat: AVAudioFormat?
    private let lock = NSLock()

    var onAudioLevel: ((Float) -> Void)?

    private let targetSampleRate: Double = 16000

    var selectedDeviceID: AudioDeviceID? {
        didSet {
            if isCapturing {
                stop()
                start()
            }
        }
    }

    func start() {
        guard !isCapturing else { return }

        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        inputNode = engine.inputNode

        if let deviceID = selectedDeviceID {
            setInputDevice(deviceID)
        }

        // Use nil format to let CoreAudio pick optimal format (avoids -10877 errors)
        let recordingFormat = inputNode!.outputFormat(forBus: 0)
        captureFormat = recordingFormat

        let bufferSize: AVAudioFrameCount = 1024

        lock.lock()
        rawSamples.removeAll()
        lock.unlock()

        inputNode!.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Calculate RMS level from input buffer
            let level = self.calculateRMS(buffer: buffer)
            DispatchQueue.main.async {
                self.onAudioLevel?(level)
            }

            // Store raw float samples
            if let channelData = buffer.floatChannelData {
                let frameLength = Int(buffer.frameLength)
                self.lock.lock()
                self.rawSamples.append(contentsOf: UnsafeBufferPointer(start: channelData[0], count: frameLength))
                self.lock.unlock()
            }
        }

        do {
            try engine.start()
            isCapturing = true
        } catch {
            print("[AudioCaptureEngine] Failed to start: \(error)")
        }
    }

    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isCapturing = false
    }

    func getAccumulatedWAVData() -> Data {
        lock.lock()
        let samples = rawSamples
        let sourceSampleRate = captureFormat?.sampleRate ?? 48000
        lock.unlock()

        guard !samples.isEmpty else { return Data() }

        // Resample to 16kHz if needed
        let resampled: [Float]
        if abs(sourceSampleRate - targetSampleRate) > 1 {
            resampled = resample(samples, from: sourceSampleRate, to: targetSampleRate)
        } else {
            resampled = samples
        }

        // Convert float to Int16 (vDSP accelerated)
        var scaled = [Float](repeating: 0, count: resampled.count)
        var scale = Float(Int16.max)
        vDSP_vsmul(resampled, 1, &scale, &scaled, 1, vDSP_Length(resampled.count))
        var lo = Float(Int16.min)
        var hi = Float(Int16.max)
        vDSP_vclip(scaled, 1, &lo, &hi, &scaled, 1, vDSP_Length(resampled.count))
        var int16Samples = [Int16](repeating: 0, count: resampled.count)
        vDSP_vfix16(scaled, 1, &int16Samples, 1, vDSP_Length(resampled.count))

        // Create WAV data
        let pcmData = int16Samples.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }

        return createWAVHeader(for: pcmData, sampleRate: Int(targetSampleRate)) + pcmData
    }

    func clearBuffers() {
        lock.lock()
        rawSamples.removeAll()
        lock.unlock()
    }

    // MARK: - Private

    private func resample(_ samples: [Float], from sourceSampleRate: Double, to targetRate: Double) -> [Float] {
        let ratio = targetRate / sourceSampleRate
        let outputLength = Int(Double(samples.count) * ratio)
        guard outputLength > 0 else { return [] }

        var output = [Float](repeating: 0, count: outputLength)

        // vDSP accelerated interpolated resampling
        var base: Float = 0
        var increment = Float(sourceSampleRate / targetRate)
        var indices = [Float](repeating: 0, count: outputLength)
        vDSP_vramp(&base, &increment, &indices, 1, vDSP_Length(outputLength))

        // Clamp indices to valid range
        var zero: Float = 0
        var maxIndex = Float(samples.count - 1)
        vDSP_vclip(indices, 1, &zero, &maxIndex, &indices, 1, vDSP_Length(outputLength))

        vDSP_vgenp(samples, 1, indices, 1, &output, 1, vDSP_Length(outputLength), vDSP_Length(samples.count))

        return output
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        var rms: Float = 0
        vDSP_rmsqv(channelData[0], 1, &rms, vDSP_Length(buffer.frameLength))
        return min(rms * 5.0, 1.0)
    }

    private func createWAVHeader(for pcmData: Data, sampleRate: Int) -> Data {
        let bitsPerSample = 16
        let numChannels = 1
        let dataSize = pcmData.count
        let byteRate = sampleRate * numChannels * (bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)

        var header = Data()

        header.append(contentsOf: "RIFF".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian) { Array($0) })
        header.append(contentsOf: "WAVE".utf8)

        header.append(contentsOf: "fmt ".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })

        header.append(contentsOf: "data".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        return header
    }

    private func setInputDevice(_ deviceID: AudioDeviceID) {
        var deviceID = deviceID
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
    }

    // MARK: - Device Enumeration

    static func availableInputDevices() -> [(id: AudioDeviceID, name: String)] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs)

        var inputDevices: [(id: AudioDeviceID, name: String)] = []

        for deviceID in deviceIDs {
            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )

            var streamSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &streamSize)

            if streamSize > 0 {
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )

                var name: Unmanaged<CFString>?
                var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
                AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &name)
                let deviceName = name?.takeRetainedValue() as String? ?? "Unknown"

                inputDevices.append((id: deviceID, name: deviceName))
            }
        }

        return inputDevices
    }
}
