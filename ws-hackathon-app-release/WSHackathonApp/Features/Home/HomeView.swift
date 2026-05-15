//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct HomeView: View {

    @State private var showRegistryAlert = false
    @StateObject private var viewModel = HomeViewModel()

    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ─── Hero Section ───────────────────────────────
                    heroSection
                        .padding(.bottom, 8)

                    // ─── Search ─────────────────────────────────────
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // ─── Content ────────────────────────────────────
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        productGrid
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProductItem.self) { product in
                ProductDetailView(
                    product: product,
                    quantity: viewModel.quantity(for: product),
                    registryQuantity: viewModel.registryQuantity(for: product),
                    onAdd: { viewModel.addToCart(product) },
                    onRemove: { viewModel.removeFromCart(product) },
                    onAddToRegistry: {
                        if viewModel.canAddToRegistry(product) {
                            viewModel.addToRegistry(product)
                        } else {
                            showRegistryAlert = true
                        }
                    },
                    onRemoveFromRegistry: { viewModel.removeFromRegistry(product) }
                )
            }
            .onAppear {
                Task {
                    viewModel.bind(
                        cartRepository: cartRepository,
                        registryRepository: registryRepository
                    )
                    await viewModel.fetchProducts()
                }
            }
            .alert("Create a Registry", isPresented: $showRegistryAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please navigate to the Registry tab using the bottom bar to create a registry first.")
            }
        }
    }
}

// MARK: - Sub-views

private extension HomeView {

    // ─── Hero ────────────────────────────────────────────────────────
    var heroSection: some View {
        VStack(spacing: 6) {
            Text("Ready to Shop!")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(Color.wsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Williams Sonoma · Curated for you")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.wsBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // ─── Search ──────────────────────────────────────────────────────
    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.wsCaption)

            TextField(AppStrings.Home.searchPlaceHolder, text: $viewModel.searchText)
                .font(.body)
                .foregroundStyle(Color.wsTitle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.wsCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // ─── Loading ─────────────────────────────────────────────────────
    var loadingView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 80)
            ProgressView()
                .controlSize(.large)
                .tint(Color.wsBrand)
            Text("Loading products…")
                .font(.subheadline)
                .foregroundStyle(Color.wsCaption)
            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity)
    }

    func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.wsCaption)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.wsBody)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    // ─── Product Grid ────────────────────────────────────────────────
    var productGrid: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.filteredProducts) { product in
                NavigationLink(value: product) {
                    ProductCardView(
                        product: product,
                        quantity: viewModel.quantity(for: product),
                        registryQuantity: viewModel.registryQuantity(for: product),
                        onAdd: { viewModel.addToCart(product) },
                        onRemove: { viewModel.removeFromCart(product) },
                        onAddToRegistry: {
                            if viewModel.canAddToRegistry(product) {
                                viewModel.addToRegistry(product)
                            } else {
                                showRegistryAlert = true
                            }
                        },
                        onRemoveFromRegistry: { viewModel.removeFromRegistry(product) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}
