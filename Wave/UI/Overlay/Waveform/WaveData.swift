import SwiftUI
import Observation

@Observable
final class WaveData {
    var waves: [SiriWave] = Array(repeating: SiriWave(power: 0), count: 3)

    let colors: [Color] = [
        Color(red: 173 / 255, green: 57 / 255, blue: 76 / 255),
        Color(red: 48 / 255, green: 220 / 255, blue: 155 / 255),
        Color(red: 25 / 255, green: 121 / 255, blue: 255 / 255),
    ]

    func update(power: CGFloat) {
        waves = colors.indices.map { _ in SiriWave(power: power) }
    }
}
