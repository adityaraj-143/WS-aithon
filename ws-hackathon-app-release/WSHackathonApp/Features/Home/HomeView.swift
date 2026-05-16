//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    private let bgColor = Color.appBackground
    
    var body: some View {
        NavigationStack(path: $tabBarVM.homePath) {
            ZStack {
                bgColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerView
                        searchBar
                        filterCategories
                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.filteredProducts.isEmpty && !viewModel.searchText.isEmpty {
                            emptySearchView
                        } else {
                            productsGrid
                        }
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarHidden(true)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .detail(let product):
                    ProductDetailView(viewModel: ProductDetailViewModel(product: product))
                }
            }
            .onAppear {
                Task {
                    viewModel.bind(cartRepository: cartRepository, registryRepository: registryRepository)
                    await viewModel.fetchProducts()
                }
            }
        }
    }
}

// MARK: - HomeView Components
private extension HomeView {
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Home")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(.textPrimary)
                
                Text("Curate your perfect collection")
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 18))
            
            TextField("Search products, brands...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.brandAccentWash)
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    var filterCategories: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Browse Categories")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 20)
            
            let displayCategories = viewModel.categories
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(displayCategories, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    viewModel.activeCategoryFilter = category
                                }
                            }) {
                                categoryCard(for: category)
                                    .padding(.horizontal, 20)
                                    .containerRelativeFrame(.horizontal)
                            }
                            .id(category)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .frame(height: 220)
                .onReceive(Timer.publish(every: 4, on: .main, in: .common).autoconnect()) { _ in
                    if let currentIndex = displayCategories.firstIndex(of: viewModel.selectedCategory) {
                        let nextIndex = (currentIndex + 1) % displayCategories.count
                        let nextCategory = displayCategories[nextIndex]
                        withAnimation(.easeInOut(duration: 0.8)) {
                            viewModel.selectedCategory = nextCategory
                            proxy.scrollTo(nextCategory, anchor: .center)
                        }
                    }
                }
            }
            .onAppear {
                if viewModel.selectedCategory == "Kitchen" {
                    viewModel.selectedCategory = "All"
                }
            }
        }
        .padding(.bottom, 32)
    }
    
    func categoryCard(for category: String) -> some View {
        let imageUrl = viewModel.imageURL(for: category)
        let isActiveFilter = viewModel.activeCategoryFilter == category
        let displayTitle = category == "All" ? "All Essentials" : "\(category)"
        
        return ZStack(alignment: .bottomLeading) {
            Color.clear
                .overlay(
                    CustomAsyncImage(url: imageUrl)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear, Color.black.opacity(0.1)]),
                startPoint: .bottom,
                endPoint: .top
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Text(displayTitle)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundColor(.white)
                .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isActiveFilter ? 0.96 : 1.0)
        .shadow(color: Color.black.opacity(isActiveFilter ? 0.12 : 0.06), radius: isActiveFilter ? 16 : 10, x: 0, y: isActiveFilter ? 8 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActiveFilter)
    }
    
    var productsGrid: some View {
        VStack(spacing: 0) {
            HStack {
                let sectionTitle = viewModel.activeCategoryFilter == "All" ? "All Essentials" : "\(viewModel.activeCategoryFilter) Essentials"
                Text(sectionTitle)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .leading,
                spacing: 24
            ) {
                ForEach(viewModel.filteredProducts) { product in
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
                                tabBarVM.selectTab(.registry)
                            }
                        },
                        onRemoveFromRegistry: { viewModel.removeFromRegistry(product) },
                        onSelect: {
                            tabBarVM.navigateToDetail(product)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .id(viewModel.activeCategoryFilter)
            .transition(.opacity)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    var emptySearchView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No results found")
                .font(.system(size: 16, weight: .medium))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
