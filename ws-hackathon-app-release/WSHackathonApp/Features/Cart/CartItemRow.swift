//
//  CartItemRow.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct CartItemRow: View {

    let item: CartItem
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // ─── Image ───────────────────────────────────────
            CustomAsyncImage(url: item.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // ─── Info ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text("$\(item.price, specifier: "%.2f")")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)

                Spacer(minLength: 0)

                // Stepper
                HStack(spacing: 14) {
                    Button(action: onRemove) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .semibold).monospacedDigit())
                        .frame(minWidth: 18)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.brandAccentWash)
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            // ─── Line Total ──────────────────────────────────
            Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(.textPrimary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
