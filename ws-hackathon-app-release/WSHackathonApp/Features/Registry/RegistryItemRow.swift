//
//  RegistryItemRow.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct RegistryItemRow: View {

    @StateObject private var viewModel: RegistryItemRowViewModel

    init(viewModel: RegistryItemRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 14) {

            // ─── Image ───────────────────────────────────────
            CustomAsyncImage(url: viewModel.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // ─── Info ────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.wsTitle)
                    .lineLimit(2)

                Text(viewModel.priceText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.wsBrand)

                Spacer(minLength: 0)

                StepperPill(
                    count: Int(viewModel.quantityText) ?? 0,
                    onIncrement: viewModel.increaseQty,
                    onDecrement: viewModel.decreaseQty
                )
            }

            Spacer(minLength: 0)

            // ─── Actions ─────────────────────────────────────
            VStack(spacing: 14) {
                Button(action: viewModel.addToCart) {
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.wsBrand)
                        .frame(width: 36, height: 36)
                        .background(Color.wsBrandLight)
                        .clipShape(Circle())
                }

                Button(action: viewModel.removeItem) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.wsDestructive)
                        .frame(width: 36, height: 36)
                        .background(Color.wsDestructive.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .wsCard()
    }
}
