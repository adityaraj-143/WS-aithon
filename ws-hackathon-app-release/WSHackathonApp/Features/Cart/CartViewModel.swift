//
//  CartViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var items: [CartItem] = []
    private var cancellable: AnyCancellable?
    private var repository: CartRepository?
    
    func bind(repository: CartRepository) {
        self.repository = repository
        self.items = repository.items
        
        cancellable = repository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedItems in
                self?.items = updatedItems
            }
    }
    
    var isEmptyCart: Bool {
        items.isEmpty
    }
    
    var totalPriceText: String {
        String(format: "$%.2f", repository?.totalPrice ?? 0)
    }
    
    func removeItem(_ item: CartItem) {
        repository?.remove(productId: item.id)
    }
    
    func add(_ item: CartItem) {
        repository?.increaseQuantity(productId: item.id)
    }
    
    @Published private(set) var recommendations: [ProductItem] = []

    func updateRecommendations(allProducts: [ProductItem]) {
        let cartIds = Set(items.map { $0.id })
        
        let cartCategories = Set(allProducts.filter { cartIds.contains($0.id) }.compactMap { $0.productType })
        
        var suggested: [ProductItem] = []
        var fallback: [ProductItem] = []
        
        for product in allProducts {
            guard !cartIds.contains(product.id) else { continue }
            
            if let type = product.productType, cartCategories.contains(type) {
                suggested.append(product)
            } else {
                fallback.append(product)
            }
        }
        
        let finalRecommendations = (suggested + fallback).prefix(6)
        self.recommendations = Array(finalRecommendations)
    }

    func add(product: ProductItem) {
        repository?.add(product: product)
    }
    
}
