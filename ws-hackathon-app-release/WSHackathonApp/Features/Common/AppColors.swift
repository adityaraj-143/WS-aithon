//
//  AppColors.swift
//  WSHackathonApp
//

import SwiftUI

// MARK: - Design Tokens

// A cohesive color system inspired by Apple's native aesthetic
// with a warm teal accent palette.
extension Color {

    // MARK: - Brand

    static let brandPrimary        = Color(hex: "9C6B4F") // richer terracotta clay
    static let brandPrimaryPressed = Color(hex: "7F543D")
    static let brandSecondary      = Color(hex: "D8C2B3")
    static let brandAccentWash     = Color(hex: "F6F1EC")

    // MARK: - Backgrounds

    static let appBackground       = Color(hex: "F4F1ED") // warmer soft stone
    static let surfacePrimary      = Color(hex: "FFFFFF")
    static let surfaceElevated     = Color(hex: "FCFBFA")
    static let surfaceOverlay      = Color.black.opacity(0.04)

    // MARK: - Text

    static let textPrimary         = Color(hex: "181716") // softer than pure black
    static let textSecondary       = Color(hex: "5E5A57")
    static let textTertiary        = Color(hex: "8E8A86")
    static let textMuted           = Color(hex: "B7B2AE")

    // MARK: - Borders

    static let borderSubtle        = Color(hex: "E8E2DC")
    static let borderSelected      = Color(hex: "9C6B4F")

    // MARK: - Semantic

    static let wsSuccess           = Color(hex: "66785F")
    static let wsDestructive       = Color(hex: "A85C52")
    static let wsWarning           = Color(hex: "C89B56")
}
