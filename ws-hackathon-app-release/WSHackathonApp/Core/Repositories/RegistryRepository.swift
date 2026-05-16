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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSocketListeners()
    }
    
    private func setupSocketListeners() {
        NotificationCenter.default.addObserver(forName: .didReceiveRegistryUpdate, object: nil, queue: .main) { [weak self] notification in
            guard let dict = notification.object as? [String: Any],
                  let self = self else { return }
            self.applyRemoteUpdate(dict)
        }
    }
    
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
        
        // Joining room for the new registry
        SocketService.shared.joinRoom(registryId: newRegistry.id.uuidString)
    }
    
    // MARK: - Add Product
    
    func addProduct(_ product: ProductItem) {
        guard let registry = currentRegistry else { return }
        addProduct(product, to: registry.id)
    }
    
    func addProduct(_ product: ProductItem, to registryId: UUID) {
        guard let index = registries.firstIndex(where: { $0.id == registryId }) else { return }
        var registry = registries[index]
        
        let price = product.price ?? 0.0
        
        if let itemIndex = registry.items.firstIndex(where: { $0.id == product.id }) {
            registry.items[itemIndex].quantity += 1
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
        
        registries[index] = registry
        if activeRegistryId == registryId {
            currentRegistry = registry
        }
        
        // SYNC: Push to other users
        syncRegistry(registry)
    }
    
    // MARK: - Quantity Updates
    
    func increaseQty(_ productId: String) {
        guard var registry = currentRegistry else { return }
        
        if let index = registry.items.firstIndex(where: { $0.id == productId }) {
            registry.items[index].quantity += 1
            currentRegistry = registry
            syncRegistry(registry)
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
        syncRegistry(registry)
    }
    
    // MARK: - Remove Item
    
    func removeItem(_ productId: String) {
        guard var registry = currentRegistry else { return }
        registry.items.removeAll { $0.id == productId }
        currentRegistry = registry
        syncRegistry(registry)
    }
    
    // MARK: - Voting
    
    func upvoteItem(_ productId: String) {
        guard var registry = currentRegistry else { return }
        guard let index = registry.items.firstIndex(where: { $0.id == productId }) else { return }
        
        let userId = SocketService.shared.currentUserId
        
        // Toggle logic: If already upvoted, remove it. Else add upvote, remove downvote.
        if registry.items[index].upvoters.contains(userId) {
            registry.items[index].upvoters.remove(userId)
        } else {
            registry.items[index].upvoters.insert(userId)
            registry.items[index].downvoters.remove(userId)
        }
        
        currentRegistry = registry
        syncRegistry(registry)
    }
    
    func downvoteItem(_ productId: String) {
        guard var registry = currentRegistry else { return }
        guard let index = registry.items.firstIndex(where: { $0.id == productId }) else { return }
        
        let userId = SocketService.shared.currentUserId
        
        // Toggle logic: If already downvoted, remove it. Else add downvote, remove upvote.
        if registry.items[index].downvoters.contains(userId) {
            registry.items[index].downvoters.remove(userId)
        } else {
            registry.items[index].downvoters.insert(userId)
            registry.items[index].upvoters.remove(userId)
        }
        
        currentRegistry = registry
        syncRegistry(registry)
    }
    
    // MARK: - Sync Helpers
    
    private func syncRegistry(_ registry: Registry) {
        // Convert to dict for socket
        let itemsDict = registry.items.map { item -> [String: Any] in
            return [
                "id": item.id,
                "title": item.title,
                "price": item.price,
                "imageUrl": item.imageUrl ?? "",
                "quantity": item.quantity,
                "upvoters": Array(item.upvoters),
                "downvoters": Array(item.downvoters)
            ]
        }
        
        let registryDict: [String: Any] = [
            "id": registry.id.uuidString,
            "firstName": registry.firstName,
            "lastName": registry.lastName,
            "items": itemsDict
        ]
        
        SocketService.shared.syncRegistry(id: registry.id.uuidString, data: registryDict)
    }
    
    private func applyRemoteUpdate(_ dict: [String: Any]) {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        // Find if we have this registry
        if let index = registries.firstIndex(where: { $0.id == id }) {
            var registry = registries[index]
            
            // Update items
            if let itemsArray = dict["items"] as? [[String: Any]] {
                registry.items = itemsArray.compactMap { itemDict -> RegistryItem? in
                    guard let itemId = itemDict["id"] as? String,
                          let title = itemDict["title"] as? String,
                          let price = itemDict["price"] as? Double,
                          let qty = itemDict["quantity"] as? Int else { return nil }
                    
                    let upvotersArray = itemDict["upvoters"] as? [String] ?? []
                    let downvotersArray = itemDict["downvoters"] as? [String] ?? []
                    
                    return RegistryItem(
                        id: itemId,
                        title: title,
                        price: price,
                        imageUrl: itemDict["imageUrl"] as? String,
                        quantity: qty,
                        upvoters: Set(upvotersArray),
                        downvoters: Set(downvotersArray)
                    )
                }
            }
            
            registries[index] = registry
            if activeRegistryId == id {
                currentRegistry = registry
            }
        }
    }
    
    func quantity(for registryItem: RegistryItem) -> Int {
        currentRegistry?.items.first(where: { $0.id == registryItem.id })?.quantity ?? 0
    }
}
