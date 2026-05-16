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
    static let brandPrimary        = Color(hex: "A07459") // Warm Clay
    static let brandPrimaryPressed = Color(hex: "8A634A") // Darker Clay
    static let brandSecondary      = Color(hex: "C7AE9D") // Soft Taupe
    static let brandAccentWash     = Color(hex: "F5EFEB") // Subtle Highlight
    
    // ─── Surfaces ────────────────────────────────────
    static let appBackground       = Color(hex: "F9F8F6") // Warm Ivory
    static let surfacePrimary      = Color.white
    static let surfaceElevated     = Color.white
    static let surfaceOverlay      = Color.black.opacity(0.05)
    
    // ─── Text ────────────────────────────────────────
    static let textPrimary         = Color(hex: "1A1C1C") // Deep Graphite
    static let textSecondary       = Color(hex: "6B6D6D") // Muted Slate
    static let textTertiary        = Color(hex: "9A9C9C") // Soft Gray
    static let textMuted           = Color(hex: "C4C6C6") // Ghost Gray
    
    // ─── Borders ─────────────────────────────────────
    static let borderSubtle        = Color(white: 0.92)
    static let borderSelected      = Color(hex: "A07459")
    
    // ─── Semantic ────────────────────────────────────
    static let wsSuccess           = Color(hex: "6B7D6B") // Sage Green
    static let wsDestructive       = Color(hex: "B05B5B") // Muted Terracotta
    static let wsWarning           = Color(hex: "D9A75F") // Ocher Gold
    
    // Legacy support (to be phased out during migration)
    static let wsBrand             = brandPrimary
    static let wsBackground        = appBackground
}
