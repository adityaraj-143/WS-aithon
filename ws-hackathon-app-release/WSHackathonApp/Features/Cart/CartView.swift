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

    private let bgColor = Color.appBackground
    private let brandColor = Color.brandPrimary
    
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
                items: viewModel.selectedItems,
                totalPrice: viewModel.selectedTotalPrice,
                onPaySuccess: {
                    withAnimation {
                        let selected = viewModel.selectedItems
                        for item in selected {
                            cartRepository.removeItemCompletely(productId: item.id)
                        }
                        viewModel.selectedCheckoutSections.removeAll()
                    }
                }
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
                .foregroundColor(.textPrimary)
            
            if !viewModel.isEmptyCart {
                Text("\(viewModel.items.reduce(0) { $0 + $1.quantity }) items in your cart")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
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
                    .fill(Color.brandAccentWash)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cart")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("Your Cart is Empty")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(.textPrimary)
                
                Text("Explore our curated collection and\nadd items to start your journey.")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
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
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Accordion sections
                    accordionSectionsStack
                        .padding(.horizontal, 20)

                    // Recommendations
                    smartRecommendationsSection
                        .padding(.top, 24)
                }
                .padding(.bottom, viewModel.selectedCheckoutSections.isEmpty ? 60 : 180)
            }

            // Checkout bar
            if !viewModel.selectedCheckoutSections.isEmpty {
                checkoutBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // ─── Accordion Sections ──────────────────────────────────────
    var accordionSectionsStack: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.sections) { section in
                VStack(alignment: .leading, spacing: 0) {
                    // Tappable Header
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.toggleSection(section.id)
                        }
                    } label: {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.system(size: 19, weight: .regular, design: .serif))
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                HStack(spacing: 6) {
                                    let totalQty = section.items.reduce(0) { $0 + $1.quantity }
                                    Text("\(totalQty) \(totalQty == 1 ? "item" : "items")")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    
                                    if let eventDate = section.eventDate {
                                        Text("•")
                                            .font(.system(size: 8))
                                            .foregroundColor(.textMuted)
                                        Text(eventDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 11))
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .rotationEffect(.degrees(section.isExpanded ? 90 : 0))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Section Products
                    if section.isExpanded {
                        Divider()
                            .background(Color.borderSubtle)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            ForEach(section.items) { item in
                                CartItemRow(
                                    item: item,
                                    onAdd: {
                                        withAnimation {
                                            viewModel.add(item)
                                        }
                                    },
                                    onRemove: {
                                        withAnimation {
                                            viewModel.removeItem(item)
                                        }
                                    },
                                    onRemoveCompletely: {
                                        withAnimation {
                                            cartRepository.removeItemCompletely(productId: item.id)
                                        }
                                    }
                                )
                                
                                if item.id != section.items.last?.id {
                                    Divider()
                                        .background(Color.borderSubtle.opacity(0.5))
                                        .padding(.leading, 116)
                                        .padding(.trailing, 20)
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.borderSubtle.opacity(0.5))
                            .padding(.horizontal, 20)
                        
                        // Section Subtotal
                        HStack {
                            Text("Subtotal")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", section.totalAmount))
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(.brandPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        let isSelected = viewModel.selectedCheckoutSections.contains(section.id)
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.toggleCheckoutSection(section.id)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                Text(isSelected ? "Remove From Checkout" : "Add To Checkout")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isSelected ? Color.clear : Color.brandPrimary)
                            .foregroundColor(isSelected ? Color.brandPrimary : .white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.brandPrimary, lineWidth: isSelected ? 1 : 0)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.015), radius: 10, x: 0, y: 4)
            }
        }
    }

    // ─── Checkout Bar ────────────────────────────────────────────
    var checkoutBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.selectedSectionsText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                let itemCount = viewModel.selectedItemsCount
                Text("\(itemCount) \(itemCount == 1 ? "Item" : "Items") • \(viewModel.selectedTotalPriceText)")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            .padding(.leading, 24)
            
            Spacer()
            
            Button {
                showCheckout = true
            } label: {
                Text("Checkout")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.brandPrimary)
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
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recommendations) { product in
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    Color.borderSubtle
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
                                            .foregroundColor(.textTertiary)
                                            .lineLimit(1)
                                    }
                                    
                                    Text(product.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                        .lineLimit(2)
                                        .frame(minHeight: 32, alignment: .topLeading)

                                    Text(product.price?.formatted(.currency(code: "USD")) ?? "$0.00")
                                        .font(.system(size: 12))
                                        .foregroundColor(.brandPrimary)
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
                                        .background(brandColor)
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
