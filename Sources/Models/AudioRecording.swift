import Foundation
import SwiftData

// CloudKit-compatible: all non-optional properties have defaults.
// The relationship back to RepertoirePiece is optional (CloudKit requirement).
@Model
final class AudioRecording {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var duration: TimeInterval = 0.0
    /// Name of the .m4a file stored in the app's Documents directory.
    var fileName: String = ""

    /// Back-reference to the owning piece (set automatically via @Relationship).
    var piece: RepertoirePiece?

    init(fileName: String, duration: TimeInterval = 0) {
        self.id = UUID()
        self.createdAt = Date.now
        self.duration = duration
        self.fileName = fileName
    }

    // MARK: - Derived helpers

    /// Full URL of the audio file in Documents.
    var fileURL: URL? {
        guard !fileName.isEmpty else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    /// Human-readable duration string (e.g. "1:23").
    var formattedDuration: String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
