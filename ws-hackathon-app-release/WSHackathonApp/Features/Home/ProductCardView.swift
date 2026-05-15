//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct ProductCardView: View {
    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {

            // ─── Product Image ───────────────────────────────
            productImage

            // ─── Info + Actions ──────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.wsTitle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let price = product.price {
                    Text(price, format: .currency(code: "USD"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.wsBrand)
                }

                Spacer(minLength: 4)

                // ─── Cart Control ────────────────────────────
                HStack(spacing: 10) {
                    if quantity == 0 {
                        Button(action: onAdd) {
                            Label("Add", systemImage: "cart.badge.plus")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.wsBrand)
                                .clipShape(Capsule())
                        }
                    } else {
                        StepperPill(
                            count: quantity,
                            onIncrement: onAdd,
                            onDecrement: onRemove
                        )
                    }

                    Spacer()

                    // ─── Registry Toggle ──────────────────────
                    Button(action: registryQuantity == 0 ? onAddToRegistry : onRemoveFromRegistry) {
                        Image(systemName: registryQuantity == 0 ? "gift" : "gift.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(registryQuantity == 0 ? Color.wsBrand : .white)
                            .frame(width: 34, height: 34)
                            .background(registryQuantity == 0
                                        ? Color.wsBrandLight
                                        : Color.wsBrand)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .wsCard()
    }

    // ─── Image View ──────────────────────────────────────────────
    private var productImage: some View {
        AsyncImage(url: product.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                ZStack {
                    Color.wsElevated
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(Color.wsCaption)
                }
            default:
                ZStack {
                    Color.wsElevated
                    ProgressView()
                        .tint(Color.wsBrand)
                }
            }
        }
        .frame(width: 100, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
