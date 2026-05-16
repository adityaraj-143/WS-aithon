//
//  ProductDetailViewModel.swift
//  WSHackathonApp
//
//  Created by Antigravity on 15/05/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProductDetailViewModel: ObservableObject {
    let product: ProductItem
    
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    
    init(product: ProductItem) {
        self.product = product
    }
    
    func bind(cartRepository: CartRepository,
              registryRepository: RegistryRepository) {
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository
    }
    
    var quantityInCart: Int {
        cartRepository?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    var quantityInRegistry: Int {
        registryRepository?.currentRegistry?.items.first(where: { $0.id == product.id })?.quantity ?? 0
    }
    
    var hasActiveRegistry: Bool {
        registryRepository?.isActiveRegistry ?? false
    }
    
    func addToCart() {
        cartRepository?.add(product: product)
    }
    
    func removeFromCart() {
        cartRepository?.remove(productId: product.id)
    }
    
    func addToRegistry() {
        registryRepository?.addProduct(product)
    }
    
    func removeFromRegistry() {
       // registryRepository?.removeItem(product.id)
    }
}
