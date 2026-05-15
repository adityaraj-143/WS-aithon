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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.wsTitle)
                    .lineLimit(2)

                Text("$\(item.price, specifier: "%.2f")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.wsBody)

                Spacer(minLength: 0)

                StepperPill(
                    count: item.quantity,
                    onIncrement: onAdd,
                    onDecrement: onRemove
                )
            }

            Spacer(minLength: 0)

            // ─── Line Total ──────────────────────────────────
            Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)
        }
        .wsCard()
    }
}
