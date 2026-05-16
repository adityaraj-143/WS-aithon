//
//  HomeView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    private let bgColor = Color(red: 245/255, green: 243/255, blue: 237/255)
    
    var body: some View {
        NavigationStack(path: $tabBarVM.homePath) {
            ZStack {
                bgColor.ignoresSafeArea()
                
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Home")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            Text("Curated kitchen and dining essentials")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                .font(.system(size: 18))
            
            TextField("Search products, brands...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .autocorrectionDisabled()
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    var filterCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            viewModel.selectedCategory = category
                        }
                    }) {
                        filterPill(title: category, isSelected: viewModel.selectedCategory == category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
    
    func filterPill(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
            )
    }
    
    var productsGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                alignment: .leading,
                spacing: 16
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
            .padding(.horizontal, 16)
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
