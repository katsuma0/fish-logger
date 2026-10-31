import UIKit

/// Spoken updates for Photo ID and the checklist. Results replace the loading row, or fill the match
/// bar, without taking VoiceOver focus, so without these a VoiceOver user hears nothing change.
@MainActor
enum IdentifyAnnouncement {
    /// Queued, so VoiceOver finishes what it is reading (such as a chip's "Selected") first instead
    /// of being cut off. Does nothing when VoiceOver is off.
    static func post(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning, !message.isEmpty else { return }
        let spoken = NSAttributedString(
            string: message,
            attributes: [.accessibilitySpeechQueueAnnouncement: true]
        )
        UIAccessibility.post(notification: .announcement, argument: spoken)
    }
}
