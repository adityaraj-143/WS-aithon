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
    @EnvironmentObject var homeVM: HomeViewModel

    private let bgColor = Color(red: 245/255, green: 243/255, blue: 237/255)
    private let warmBrown = Color(red: 175/255, green: 155/255, blue: 130/255)
    
    @State private var showCheckout = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                bgColor.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    headerView
                    
                    if viewModel.isEmptyCart {
                        emptyState
                    } else {
                        cartContent
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.bind(repository: cartRepository)
            viewModel.updateRecommendations(allProducts: homeVM.products)
        }
        .onChange(of: viewModel.items.count) {
            viewModel.updateRecommendations(allProducts: homeVM.products)
        }
        .fullScreenCover(isPresented: $showCheckout) {
            CheckoutView(
                items: viewModel.items,
                totalPrice: cartRepository.totalPrice
            )
        }
    }
}

// MARK: - Sub-views

private extension CartView {

    // ─── Header View ─────────────────────────────────────────────
    var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cart")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            if !viewModel.isEmptyCart {
                Text("\(viewModel.items.reduce(0) { $0 + $1.quantity }) items in your cart")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // ─── Empty State ─────────────────────────────────────────────
    var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(white: 0.97))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cart")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("Your Cart is Empty")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                
                Text("Explore our curated collection and\nadd items to start your journey.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    // ─── Cart Content ────────────────────────────────────────────
    var cartContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
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

    // ─── Checkout Bar ────────────────────────────────────────────
    var checkoutBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.totalPriceText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                
                Text("Total Amount")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(.leading, 32)
            
            Spacer()
            
            Button {
                showCheckout = true
            } label: {
                Text(AppStrings.Cart.checkoutButton)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.46, green: 0.50, blue: 0.44))
                    .clipShape(Capsule())
            }
            .padding(8)
        }
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // ─── Smart Recommendations ───────────────────────────────────
    @ViewBuilder
    var smartRecommendationsSection: some View {
        if !viewModel.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Complete Your Bundle")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recommendations) { product in
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    Color(red: 0.95, green: 0.95, blue: 0.95)
                                    CustomAsyncImage(url: product.imageURL)
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .clipped()

                                VStack(alignment: .leading, spacing: 4) {
                                    if let brand = product.brand {
                                        Text(brand.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .tracking(1)
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                            .lineLimit(1)
                                    }
                                    
                                    Text(product.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .lineLimit(2)
                                        .frame(minHeight: 32, alignment: .topLeading)

                                    Text(product.price?.formatted(.currency(code: "USD")) ?? "$0.00")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
                                }
                                .padding(.top, 8)
                                .padding(.horizontal, 4)

                                Button {
                                    withAnimation {
                                        viewModel.add(product: product)
                                        viewModel.updateRecommendations(allProducts: homeVM.products)
                                    }
                                } label: {
                                    Text("+ Add to Cart")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(warmBrown)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 4)
                            }
                            .frame(width: 140)
                            .background(bgColor)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
