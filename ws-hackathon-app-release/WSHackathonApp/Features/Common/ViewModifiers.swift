//
//  ViewModifiers.swift
//  WSHackathonApp
//

import SwiftUI

// MARK: - Card Modifier

/// Gives any view a native-feeling card appearance: rounded corners,
/// adaptive background, and a subtle shadow that works in both light & dark.
struct WSCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

extension View {
    func wsCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        modifier(WSCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Primary Button Style

/// A large, branded capsule button inspired by the SignSync "Start Game" CTA.
struct WSPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [Color.brandPrimary, Color.brandPrimaryPressed]
                        : [Color.textMuted, Color.textMuted.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: isEnabled ? Color.brandPrimary.opacity(0.35) : .clear,
                    radius: configuration.isPressed ? 2 : 8,
                    x: 0,
                    y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Stepper Pill

/// A compact ＋/quantity/− control rendered as a capsule pill.
struct StepperPill: View {
    let count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
            }

            Text("\(count)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .frame(minWidth: 18)

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
            }
        }
        .foregroundStyle(Color.brandPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.brandAccentWash)
        .clipShape(Capsule())
    }
}

// MARK: - Stat Badge (Achievement-style)

/// A small, pastel-backed stat badge like the "7 Unlocked · 126 Total" in SignSync.
struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color
    let background: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.weight(.black))
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Section Header

struct WSSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}
