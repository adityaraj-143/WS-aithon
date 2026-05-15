//
//  AppColors.swift
//  WSHackathonApp
//

import SwiftUI

// MARK: - Design Tokens

/// A cohesive color system inspired by Apple's native aesthetic
/// with a warm teal accent palette.
extension Color {

    // ─── Brand ───────────────────────────────────────
    static let wsBrand        = Color(hex: "4ABFBF")   // Teal primary
    static let wsBrandDark    = Color(hex: "2E9E9E")   // Pressed / darker teal
    static let wsBrandLight   = Color(hex: "D6F5F2")   // Teal wash for highlights

    // ─── Surfaces ────────────────────────────────────
    static let wsBackground   = Color(UIColor.systemGroupedBackground)
    static let wsCard         = Color(UIColor.secondarySystemGroupedBackground)
    static let wsElevated     = Color(UIColor.tertiarySystemBackground)

    // ─── Text ────────────────────────────────────────
    static let wsTitle        = Color(UIColor.label)
    static let wsBody         = Color(UIColor.secondaryLabel)
    static let wsCaption      = Color(UIColor.tertiaryLabel)

    // ─── Pastel Accents (for stat cards / badges) ────
    static let pastelMint     = Color(hex: "E0FAF3")
    static let pastelLavender = Color(hex: "EEE5FF")
    static let pastelPeach    = Color(hex: "FFEEE0")
    static let pastelSky      = Color(hex: "E3F1FF")

    // ─── Semantic ────────────────────────────────────
    static let wsSuccess      = Color.green
    static let wsDestructive  = Color.red
}

// MARK: - Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
