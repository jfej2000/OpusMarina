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

@Model
final class RepertoirePiece {
    var title: String
    var composer: String
    var dateLearned: Date
    var era: MusicEra
    var status: LearningStatus
    var difficulty: Int
    var studyNotes: String?
    var webLink: URL?
    var pdfFileName: String?
    
    init(
        title: String,
        composer: String,
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
        self.era = era
        self.status = status
        self.difficulty = difficulty
        self.studyNotes = studyNotes
        self.webLink = webLink
        self.pdfFileName = pdfFileName
    }
}
