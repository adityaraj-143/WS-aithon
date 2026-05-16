//
//  HomeViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 04/04/26.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var products: [ProductItem] = []
    /// Raw DTOs exposed for the on-device AI planner (richer fields than ProductItem)
    @Published var productDTOs: [ProductItemDTO] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let categories = ["All", "Kitchen", "Dining", "Bedding"]
    
    private var hasLoaded = false
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?

    func bind(cartRepository: CartRepository,
              registryRepository: RegistryRepository) {
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository
    }
    
    // Cart
    func addToCart(_ product: ProductItem) {
        cartRepository?.add(product: product)
    }
    
    func removeFromCart(_ product: ProductItem) {
        cartRepository?.remove(productId: product.id)
    }
    
    // Registry
    func addToRegistry(_ product: ProductItem) {
        registryRepository?.addProduct(product)
    }
    
    func canAddToRegistry(_ product: ProductItem) -> Bool {
        if let registryRepository, registryRepository.isActiveRegistry {
            return true
        }
        return false
    }
    
    func removeFromRegistry(_ product: ProductItem) {
        registryRepository?.removeItem(product.id)
    }
    
    func quantity(for product: ProductItem) -> Int {
        cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    func registryQuantity(for product: ProductItem) -> Int {
        registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    var filteredProducts: [ProductItem] {
        var result = products
        
        if selectedCategory != "All" {
            result = result.filter { product in
                guard let type = product.productType?.lowercased() else { return false }
                
                switch selectedCategory {
                case "Kitchen":
                    return type.contains("dutch") || type.contains("fry-pan") || type.contains("coffee") || type.contains("cutting") || type.contains("oil")
                case "Dining":
                    return type.contains("serveware") || type.contains("cups") || type.contains("glasses") || type.contains("susan")
                case "Bedding":
                    return false
                default:
                    return true
                }
            }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
    
    func fetchProducts() async {
        guard !hasLoaded || products.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            self.productDTOs = dtos
            self.products = dtos.map { ProductItem(from: $0) }
            hasLoaded = true
        } catch {
            print("API Error: \(error)")
            errorMessage = "Failed to load products"
            hasLoaded = false
        }
        
        isLoading = false
    }
}

