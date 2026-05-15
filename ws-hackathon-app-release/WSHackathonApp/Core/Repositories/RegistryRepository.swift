//
//  RegistryRepository.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Combine
import Foundation

@MainActor
final class RegistryRepository: ObservableObject {
    
    @Published var registries: [Registry] = []
    @Published var activeRegistryId: UUID?
    
    var currentRegistry: Registry? {
        get {
            guard let id = activeRegistryId else { return nil }
            return registries.first { $0.id == id }
        }
        set {
            guard let newValue = newValue else { return }
            if let index = registries.firstIndex(where: { $0.id == newValue.id }) {
                registries[index] = newValue
            }
        }
    }
    
    // MARK: - Create
    var isActiveRegistry: Bool {
        activeRegistryId != nil
    }
    
    func createRegistry(firstName: String,
                        lastName: String,
                        event: RegistryEvent,
                        date: Date,
                        budget: String?) {
        
        let newRegistry = Registry(
            id: UUID(),
            firstName: firstName,
            lastName: lastName,
            event: event,
            date: date,
            budget: budget,
            items: []
        )
        
        registries.append(newRegistry)
        activeRegistryId = newRegistry.id
    }
    
    // MARK: - Delete Registry
    
    func deleteRegistry() {
        guard let id = activeRegistryId else { return }
        registries.removeAll { $0.id == id }
        activeRegistryId = registries.last?.id
    }
    
    // MARK: - Add Product
    
    func addProduct(_ product: ProductItem) {
        guard var registry = currentRegistry else { return }
        
        let price = product.price ?? 0.0
        
        if let index = registry.items.firstIndex(where: { $0.id == product.id }) {
            registry.items[index].quantity += 1
        } else {
            registry.items.append(
                RegistryItem(
                    id: product.id,
                    title: product.title,
                    price: price,
                    imageUrl: product.path,
                    quantity: 1
                )
            )
        }
        
        currentRegistry = registry
    }
    
    // MARK: - Remove Item
    
    func removeItem(_ productId: String) {
        guard var registry = currentRegistry else { return }
        
        registry.items.removeAll { $0.id == productId }
        currentRegistry = registry
    }
    
    // MARK: - Update Quantity
    
    func increaseQty(_ productId: String) {
        guard var registry = currentRegistry else { return }
        
        if let index = registry.items.firstIndex(where: { $0.id == productId }) {
            registry.items[index].quantity += 1
            currentRegistry = registry
        }
    }
    
    func decreaseQty(_ productId: String) {
        guard var registry = currentRegistry else { return }
        
        guard let index = registry.items.firstIndex(where: { $0.id == productId }) else { return }
        
        if registry.items[index].quantity > 1 {
            registry.items[index].quantity -= 1
        } else {
            registry.items.remove(at: index)
        }
        
        currentRegistry = registry
    }
    
    func quantity(for registryItem: RegistryItem) -> Int {
        currentRegistry?.items.first(where: { $0.id == registryItem.id })?.quantity ?? 0
    }
}
