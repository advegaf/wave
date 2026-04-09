import AVFoundation
import Observation
import Accelerate

@Observable
final class AudioCaptureEngine: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private(set) var isCapturing = false

    // Store raw float audio (capture-rate, pre-resample) for the legacy WAV path
    private var rawSamples: [Float] = []
    private var captureFormat: AVAudioFormat?
    private let lock = NSLock()

    // Resampled 16 kHz mono buffer — what whisper actually consumes.
    // Filled inline in the tap callback so the VAD can see audio in real time.
    private var resampledSamples: [Float] = []

    // Working buffer for chunking resampled audio into Silero-sized 4096-sample
    // pieces. Drained whenever we accumulate >= one chunk.
    private var vadStaging: [Float] = []

    var onAudioLevel: ((Float) -> Void)?

    /// Fires when SileroVAD reports the user has finished speaking. Replaces
    /// the old `SilenceDetector.onSilenceDetected` hook. Always called on the
    /// main queue.
    var onSpeechEnded: (() -> Void)?

    private let targetSampleRate: Double = 16000

    // MARK: - VAD wiring

    private let silero = SileroVAD()
    private var hasHeardSpeech = false
    private var hasFiredSpeechEnded = false
    private var vadConsumerTask: Task<Void, Never>?
    private var vadChunkContinuation: AsyncStream<[Float]>.Continuation?

    var selectedDeviceID: AudioDeviceID? {
        didSet {
            if isCapturing {
                stop()
                start()
            }
        }
    }

    /// Preload the Silero VAD CoreML model so the first recording doesn't pay
    /// the download/load cost. Safe to call multiple times. Best called from
    /// `RecordingCoordinator.preloadActiveModels()`.
    func prepareVAD() async {
        do {
            try await silero.prepare()
        } catch {
            print("[AudioCaptureEngine] Silero VAD preload failed: \(error)")
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
        resampledSamples.removeAll()
        vadStaging.removeAll()
        hasHeardSpeech = false
        hasFiredSpeechEnded = false
        lock.unlock()

        // Spin up the VAD consumer task. A single consumer drains the chunk
        // stream in order so SileroVAD's streaming state stays consistent.
        let (stream, cont) = AsyncStream<[Float]>.makeStream()
        vadChunkContinuation = cont
        vadConsumerTask = Task { [silero, weak self] in
            await silero.resetStream()
            for await chunk in stream {
                do {
                    if let event = try await silero.process(chunk: chunk) {
                        await self?.handleVAD(event: event)
                    }
                } catch {
                    print("[AudioCaptureEngine] VAD process error: \(error)")
                }
            }
        }

        inputNode!.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Calculate RMS level for the UI waveform
            let level = self.calculateRMS(buffer: buffer)
            DispatchQueue.main.async {
                self.onAudioLevel?(level)
            }

            guard let channelData = buffer.floatChannelData else { return }
            let frameLength = Int(buffer.frameLength)
            let bufferSamples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

            // Resample inline so VAD can see 16 kHz audio in real time.
            let sourceRate = self.captureFormat?.sampleRate ?? 48000
            let resampledChunk: [Float]
            if abs(sourceRate - self.targetSampleRate) > 1 {
                resampledChunk = self.resample(bufferSamples, from: sourceRate, to: self.targetSampleRate)
            } else {
                resampledChunk = bufferSamples
            }

            self.lock.lock()
            self.rawSamples.append(contentsOf: bufferSamples)
            self.resampledSamples.append(contentsOf: resampledChunk)
            self.vadStaging.append(contentsOf: resampledChunk)

            // Drain whole 4096-sample chunks into the VAD consumer.
            let chunkSize = SileroVAD.chunkSize
            while self.vadStaging.count >= chunkSize {
                let chunk = Array(self.vadStaging.prefix(chunkSize))
                self.vadStaging.removeFirst(chunkSize)
                self.vadChunkContinuation?.yield(chunk)
            }
            self.lock.unlock()
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

        // Tear down the VAD consumer for this recording session.
        vadChunkContinuation?.finish()
        vadChunkContinuation = nil
        vadConsumerTask?.cancel()
        vadConsumerTask = nil
    }

    /// Returns the resampled 16 kHz mono float samples accumulated since the
    /// last `clearBuffers()`. This is the new path that LocalAIEngine consumes —
    /// no WAV header round-trip.
    func getResampledSamples() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return resampledSamples
    }

    @MainActor
    private func handleVAD(event: SileroVAD.SpeechEvent) async {
        switch event {
        case .speechStarted:
            hasHeardSpeech = true
        case .speechEnded:
            // Only fire once per session, and only after we actually heard
            // speech (avoid premature stop on background noise).
            guard hasHeardSpeech, !hasFiredSpeechEnded else { return }
            hasFiredSpeechEnded = true
            onSpeechEnded?()
        }
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

        // Convert float to Int16
        var int16Samples = [Int16](repeating: 0, count: resampled.count)
        for i in 0..<resampled.count {
            let clamped = max(-1.0, min(1.0, resampled[i]))
            int16Samples[i] = Int16(clamped * Float(Int16.max))
        }

        // Create WAV data
        let pcmData = int16Samples.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }

        return createWAVHeader(for: pcmData, sampleRate: Int(targetSampleRate)) + pcmData
    }

    func clearBuffers() {
        lock.lock()
        rawSamples.removeAll()
        resampledSamples.removeAll()
        vadStaging.removeAll()
        hasHeardSpeech = false
        hasFiredSpeechEnded = false
        lock.unlock()
    }

    // MARK: - Private

    private func resample(_ samples: [Float], from sourceSampleRate: Double, to targetRate: Double) -> [Float] {
        let ratio = targetRate / sourceSampleRate
        let outputLength = Int(Double(samples.count) * ratio)
        var output = [Float](repeating: 0, count: outputLength)

        // Linear interpolation resampling
        for i in 0..<outputLength {
            let srcIndex = Double(i) / ratio
            let srcIndexInt = Int(srcIndex)
            let frac = Float(srcIndex - Double(srcIndexInt))

            if srcIndexInt + 1 < samples.count {
                output[i] = samples[srcIndexInt] * (1.0 - frac) + samples[srcIndexInt + 1] * frac
            } else if srcIndexInt < samples.count {
                output[i] = samples[srcIndexInt]
            }
        }

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
