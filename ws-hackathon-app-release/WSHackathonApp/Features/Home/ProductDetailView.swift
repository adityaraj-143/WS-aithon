//
//  ProductDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct ProductDetailView: View {

    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void

    @State private var imageScale: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ─── Product Image ───────────────────────────
                productImageSection

                // ─── Product Info ────────────────────────────
                VStack(alignment: .leading, spacing: 20) {

                    // Title + Price
                    titlePriceSection

                    Divider()

                    // Highlights
                    highlightsSection

                    Divider()

                    // Delivery Estimate
                    deliverySection

                    Divider()

                    // Description
                    descriptionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
        }
        .background(Color.wsBackground.ignoresSafeArea())
        .overlay(alignment: .bottom) { actionBar }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sub-views

private extension ProductDetailView {

    // ─── Image Hero ──────────────────────────────────────────────
    var productImageSection: some View {
        AsyncImage(url: product.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(imageScale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                imageScale = value.magnification
                            }
                            .onEnded { _ in
                                withAnimation(.spring) { imageScale = 1.0 }
                            }
                    )
            case .failure:
                ZStack {
                    Color.wsElevated
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.wsCaption)
                }
            default:
                ZStack {
                    Color.wsElevated
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.wsBrand)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // ─── Title + Price ───────────────────────────────────────────
    var titlePriceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(product.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.wsTitle)
                .fixedSize(horizontal: false, vertical: true)

            if let price = product.price {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(price, format: .currency(code: "USD"))
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Color.wsBrand)

                    if price > 50 {
                        Text("Free Shipping")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.wsSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.wsSuccess.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            // Rating stars (mock)
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < 4 ? "star.fill" : "star.leadinghalf.filled")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text("4.5")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.wsBody)
                Text("(128 reviews)")
                    .font(.caption)
                    .foregroundStyle(Color.wsCaption)
            }
        }
    }

    // ─── Highlights ──────────────────────────────────────────────
    var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            highlightRow(icon: "shippingbox.fill", color: .wsBrand,
                         text: "Ships from Williams Sonoma warehouse")
            highlightRow(icon: "arrow.triangle.2.circlepath", color: .orange,
                         text: "Easy 30-day returns & exchanges")
            highlightRow(icon: "shield.checkered", color: .green,
                         text: "Quality guaranteed · Premium materials")
            highlightRow(icon: "gift.fill", color: .purple,
                         text: "Gift wrapping available")
        }
    }

    func highlightRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.wsBody)
        }
    }

    // ─── Delivery ────────────────────────────────────────────────
    var deliverySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delivery")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            HStack(spacing: 12) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.wsBrand)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Standard Delivery")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.wsTitle)
                    Text("Estimated arrival in 5–7 business days")
                        .font(.caption)
                        .foregroundStyle(Color.wsBody)
                }
            }
            .wsCard(cornerRadius: 12, padding: 14)
        }
    }

    // ─── Description ─────────────────────────────────────────────
    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About this product")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            Text("Crafted with care by Williams Sonoma artisans, this product combines premium materials with exceptional design. Perfect for entertaining or everyday use, it makes a thoughtful gift for any occasion.")
                .font(.subheadline)
                .foregroundStyle(Color.wsBody)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // ─── Bottom Action Bar ───────────────────────────────────────
    var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {

                // Registry toggle
                Button(action: registryQuantity == 0 ? onAddToRegistry : onRemoveFromRegistry) {
                    Image(systemName: registryQuantity == 0 ? "gift" : "gift.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(registryQuantity == 0 ? Color.wsBrand : .white)
                        .frame(width: 48, height: 48)
                        .background(registryQuantity == 0 ? Color.wsBrandLight : Color.wsBrand)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Cart button / stepper
                if quantity == 0 {
                    Button(action: onAdd) {
                        Label("Add to Cart", systemImage: "cart.badge.plus")
                    }
                    .buttonStyle(WSPrimaryButtonStyle())
                } else {
                    HStack {
                        StepperPill(
                            count: quantity,
                            onIncrement: onAdd,
                            onDecrement: onRemove
                        )
                        Spacer()
                        Text("In Cart")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.wsBrand)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.wsCard.ignoresSafeArea(edges: .bottom))
        }
    }
}
