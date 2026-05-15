//
//  CartView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.wsBackground.ignoresSafeArea()

                if viewModel.isEmptyCart {
                    emptyState
                } else {
                    cartContent
                }
            }
            .navigationTitle(AppStrings.Cart.title)
        }
        .onAppear {
            viewModel.bind(repository: cartRepository)
        }
    }
}

// MARK: - Sub-views

private extension CartView {

    // ─── Empty State ─────────────────────────────────────────────
    var emptyState: some View {
        VStack {
            Spacer()
            EmptyCartView()
            Spacer()
        }
    }

    // ─── Cart Content ────────────────────────────────────────────
    var cartContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Stats header
                    summaryHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Item list
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            CartItemRow(
                                item: item,
                                onAdd: { viewModel.add(item) },
                                onRemove: { viewModel.removeItem(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Recommendations
                    smartRecommendationsSection
                        .padding(.top, 24)
                }
                .padding(.bottom, 130)
            }

            // Checkout bar
            checkoutBar
        }
    }

    // ─── Summary Header (Achievement-style stat badges) ──────────
    var summaryHeader: some View {
        HStack(spacing: 12) {
            StatBadge(
                value: "\(viewModel.items.count)",
                label: "Items",
                icon: "bag.fill",
                tint: .wsBrand,
                background: .pastelMint
            )
            StatBadge(
                value: "\(viewModel.items.reduce(0) { $0 + $1.quantity })",
                label: "Qty",
                icon: "number",
                tint: .purple,
                background: .pastelLavender
            )
            StatBadge(
                value: viewModel.totalPriceText,
                label: "Total",
                icon: "dollarsign.circle.fill",
                tint: .orange,
                background: .pastelPeach
            )
        }
    }

    // ─── Checkout Bar ────────────────────────────────────────────
    var checkoutBar: some View {
        VStack(spacing: 14) {
            HStack {
                Text(AppStrings.Cart.total)
                    .font(.headline)
                    .foregroundStyle(Color.wsBody)
                Spacer()
                Text(viewModel.totalPriceText)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.wsTitle)
            }

            Button {
                // TODO: Checkout flow
            } label: {
                Text(AppStrings.Cart.checkoutButton)
            }
            .buttonStyle(WSPrimaryButtonStyle())
        }
        .padding(20)
        .background(
            Color.wsCard
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // ─── Smart Recommendations ───────────────────────────────────
    var smartRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            WSSectionHeader(title: "Complete Your Bundle")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<4) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack {
                                Color.wsElevated
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundStyle(Color.wsBrand)
                            }
                            .frame(width: 130, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Text("Matching Item \(index + 1)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.wsTitle)
                                .lineLimit(1)

                            Text("$49.99")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.wsBody)

                            Button {
                                // Mock add
                            } label: {
                                Text("Add")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.wsBrand)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .frame(width: 130)
                        .wsCard(cornerRadius: 14, padding: 10)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
