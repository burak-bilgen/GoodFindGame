import AVFoundation
import OSLog
import UIKit

/// All sounds are short original synthesized tones. Ambient audio respects silent mode.
@MainActor enum GameFeel {
    enum Cue { case submitted, reply, accepted, purchase, offer, reveal, defect, profit, loss }
    private static let audio = FeedbackAudio()
    static func play(_ cue: Cue) {
        guard UIApplication.shared.applicationState == .active else { return }
        let notification = UINotificationFeedbackGenerator()
        switch cue {
        case .accepted, .purchase, .profit: notification.notificationOccurred(.success)
        case .defect, .loss: notification.notificationOccurred(.warning)
        case .submitted: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .reply, .offer, .reveal: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        guard UserDefaults.standard.bool(forKey: "gameSoundEnabled") else { return }
        let notes: [Double] = switch cue {
        case .submitted: [440]
        case .reply: [560, 660]
        case .accepted, .purchase: [523, 659, 784]
        case .offer: [659, 880]
        case .reveal: [440, 523]
        case .defect, .loss: [330, 247]
        case .profit: [523, 659, 1047]
        }
        audio.play(notes)
    }

}

/// Every access to the session configuration and player is serialized on this
/// queue. Audio setup and sample synthesis must never block the UI thread.
private final class FeedbackAudio: @unchecked Sendable {
    private let queue = DispatchQueue(label: "ProjectFlip.feedbackAudio", qos: .userInitiated)
    private var player: AVAudioPlayer?
    private var configured = false

    func play(_ notes: [Double]) {
        queue.async { [self] in
            do {
                if !configured {
                    try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                    configured = true
                }
                player = try AVAudioPlayer(data: Self.wave(notes))
                player?.volume = 0.20
                player?.play()
            } catch { Logger(subsystem: "ProjectFlip", category: "Audio").error("Feedback unavailable: \(String(describing: error), privacy: .public)") }
        }
    }
    private static func wave(_ notes: [Double]) -> Data {
        let rate = 22_050
        let count = 1_764
        var samples = Data()
        func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        for frequency in notes {
            for index in 0..<count {
                let envelope = sin(Double.pi * Double(index) / Double(count))
                let value = Int16(sin(2 * Double.pi * frequency * Double(index) / Double(rate)) * envelope * 9_000)
                append(value, to: &samples)
            }
        }
        var data = Data("RIFF".utf8)
        append(UInt32(36 + samples.count), to: &data); data.append(Data("WAVEfmt ".utf8))
        append(UInt32(16), to: &data); append(UInt16(1), to: &data); append(UInt16(1), to: &data)
        append(UInt32(rate), to: &data); append(UInt32(rate * 2), to: &data)
        append(UInt16(2), to: &data); append(UInt16(16), to: &data)
        data.append(Data("data".utf8)); append(UInt32(samples.count), to: &data); data.append(samples)
        return data
    }
}
