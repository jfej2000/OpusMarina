import Foundation
import SwiftData

enum MusicEra: String, Codable, CaseIterable, Identifiable {
    case baroque = "Barroco"
    case classical = "Clasicismo"
    case romantic = "Romanticismo"
    case impressionist = "Impresionismo"
    case contemporary = "Siglo XX / Pop / BSO"
    
    var id: Self { self }
}

enum LearningStatus: String, Codable, CaseIterable, Identifiable {
    case toLearn = "Por aprender"
    case learning = "En estudio"
    case learned = "Aprendida"
    case toReview = "Para repasar"
    
    var id: Self { self }
}

// CloudKit Requirements:
// - All non-optional properties MUST have default values.
// - No @Attribute(.unique) — CloudKit does not support it.
// - Relationships must be optional or have defaults.
@Model
final class RepertoirePiece {
    // CloudKit: non-optional properties need default values
    var title: String = ""
    var composer: String = ""
    var dateLearned: Date = Date.now
    var eraRaw: String = MusicEra.romantic.rawValue   // Store as raw String for CloudKit compatibility
    var statusRaw: String = LearningStatus.toLearn.rawValue
    var difficulty: Int = 3
    var totalPracticeTime: TimeInterval = 0.0
    // Optionals are CloudKit-safe
    var studyNotes: String?
    var webLink: URL?
    var pdfFileName: String?
    /// Audio recordings for this piece. Cascade-delete removes files from disk in AudioRecorderService.
    @Relationship(deleteRule: .cascade, inverse: \AudioRecording.piece)
    var recordings: [AudioRecording]? = []

    // Computed helpers (not persisted) for convenience
    @Transient var era: MusicEra {
        get { MusicEra(rawValue: eraRaw) ?? .romantic }
        set { eraRaw = newValue.rawValue }
    }

    @Transient var status: LearningStatus {
        get { LearningStatus(rawValue: statusRaw) ?? .toLearn }
        set { statusRaw = newValue.rawValue }
    }

    init(
        title: String = "",
        composer: String = "",
        dateLearned: Date = .now,
        era: MusicEra = .romantic,
        status: LearningStatus = .toLearn,
        difficulty: Int = 3,
        studyNotes: String? = nil,
        webLink: URL? = nil,
        pdfFileName: String? = nil
    ) {
        self.title = title
        self.composer = composer
        self.dateLearned = dateLearned
        self.eraRaw = era.rawValue
        self.statusRaw = status.rawValue
        self.difficulty = difficulty
        self.studyNotes = studyNotes
        self.webLink = webLink
        self.pdfFileName = pdfFileName
    }
}

extension TimeInterval {
    var formattedPracticeTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
