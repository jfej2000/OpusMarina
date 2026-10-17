import Foundation
import SwiftData
import SwiftUI

// CloudKit Requirements:
// - All non-optional properties MUST have default values.
// - No @Attribute(.unique) — CloudKit does not support it.
// - Relationships must be optional or have defaults.
@Model
final class PieceFolder {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#0F4C81"
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify)
    var pieces: [RepertoirePiece]? = []

    init(
        name: String = "",
        colorHex: String = "#0F4C81"
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date.now
        self.pieces = []
    }
}

// MARK: - Color & Preset Helpers
extension PieceFolder {
    var color: Color {
        Color(hex: colorHex)
    }

    static let defaultColorHex = "#0F4C81"

    static let presetColors: [(name: String, hex: String, color: Color)] = [
        ("Azul", "#0F4C81", Color(hex: "#0F4C81")),
        ("Rojo", "#E02424", Color(hex: "#E02424")),
        ("Verde", "#057A55", Color(hex: "#057A55")),
        ("Amarillo", "#D97706", Color(hex: "#D97706")),
        ("Morado", "#7E3AF2", Color(hex: "#7E3AF2")),
        ("Naranja", "#FF5A1F", Color(hex: "#FF5A1F"))
    ]
}

extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 15, 76, 129)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    func toHex() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let r = Int(round(red * 255))
            let g = Int(round(green * 255))
            let b = Int(round(blue * 255))
            return String(format: "#%02X%02X%02X", r, g, b)
        }
        #endif
        return "#0F4C81"
    }
}
