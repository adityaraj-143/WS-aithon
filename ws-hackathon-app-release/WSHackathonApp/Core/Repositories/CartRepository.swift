//
//  CartRepository.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import Combine

@MainActor
final class CartRepository: ObservableObject {
    
    @Published private(set) var items: [CartItem] = []
    
    // MARK: - Add Item
    func add(product: ProductItem,
             quantity: Int = 1,
             registryId: String? = nil,
             registryName: String? = nil,
             registryEventDate: Date? = nil) {
        guard let priceValue = product.price else { return }
        
        let cartItemId = registryId != nil ? "\(product.id)_\(registryId!)" : product.id
        
        if let index = items.firstIndex(where: { $0.id == cartItemId }) {
            items[index].quantity += quantity
        } else {
            let newItem = CartItem(
                id: cartItemId,
                title: product.title,
                price: priceValue,
                path: product.path,
                quantity: quantity,
                registryId: registryId,
                registryName: registryName,
                registryEventDate: registryEventDate
            )
            items.append(newItem)
        }
    }
    
    // MARK: - Remove Item
    func remove(productId: String) {
        guard let index = items.firstIndex(where: { $0.id == productId }) else { return }
        if items[index].quantity > 1 {
            items[index].quantity -= 1
        } else {
            items.remove(at: index)
        }
    }
    
    // MARK: - Total Price
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    // MARK: - Total Count
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    func increaseQuantity(productId: String) {
        guard let index = items.firstIndex(where: { $0.id == productId }) else { return }
        items[index].quantity += 1
    }

    func removeItemCompletely(productId: String) {
        items.removeAll(where: { $0.id == productId })
    }

    func setItems(_ newItems: [CartItem]) {
        self.items = newItems
    }
}
