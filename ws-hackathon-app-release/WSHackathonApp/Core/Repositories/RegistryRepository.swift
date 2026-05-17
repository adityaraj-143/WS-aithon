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
    
    private var deletedRegistryIds: Set<UUID> {
        get {
            guard let array = UserDefaults.standard.stringArray(forKey: "deleted_registry_ids") else { return [] }
            return Set(array.compactMap { UUID(uuidString: $0) })
        }
        set {
            let array = newValue.map { $0.uuidString }
            UserDefaults.standard.set(array, forKey: "deleted_registry_ids")
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFromDisk()
        setupSocketListeners()
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(registries) {
            UserDefaults.standard.set(encoded, forKey: "saved_registries")
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "saved_registries"),
           let decoded = try? JSONDecoder().decode([Registry].self, from: data) {
            self.registries = decoded
        }
    }
    
    private func setupSocketListeners() {
        NotificationCenter.default.addObserver(forName: .didReceiveRegistryUpdate, object: nil, queue: .main) { [weak self] notification in
            guard let dict = notification.object as? [String: Any],
                  let self = self else { return }
            Task { @MainActor in
                self.applyRemoteUpdate(dict)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .didFetchUserRegistries, object: nil, queue: .main) { [weak self] notification in
            guard let array = notification.object as? [[String: Any]],
                  let self = self else { return }
            Task { @MainActor in
                self.applyBulkRemoteUpdate(array)
            }
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
                saveToDisk()
            }
        }
    }
    
    // MARK: - Create
    var isActiveRegistry: Bool {
        activeRegistryId != nil
    }
    
    func createRegistry(id: UUID? = nil,
                        firstName: String,
                        lastName: String,
                        event: RegistryEvent,
                        date: Date,
                        budget: String?) {
        
        let newRegistry = Registry(
            id: id ?? UUID(),
            firstName: firstName,
            lastName: lastName,
            event: event,
            date: date,
            budget: budget,
            items: [],
            collaboratorNames: [SocketService.shared.currentDisplayName]
        )
        
        registries.append(newRegistry)
        activeRegistryId = newRegistry.id
        saveToDisk()
        
        if id == nil {
            // SYNC: Push the new registry to the server only if it's brand new
            syncRegistry(newRegistry)
        }
        
        // Joining room for the registry
        SocketService.shared.joinRoom(registryId: newRegistry.id.uuidString)
    }
    
    // MARK: - Delete
    
    func deleteRegistry(id: UUID) {
        // Track as deleted to ignore incoming socket sync updates for it
        var currentDeleted = deletedRegistryIds
        currentDeleted.insert(id)
        deletedRegistryIds = currentDeleted
        
        // 1. Remove from registries list
        registries.removeAll { $0.id == id }
        
        // 2. Clear or update activeRegistryId if needed
        if activeRegistryId == id {
            activeRegistryId = registries.first?.id
        }
        
        // 3. Save to disk
        saveToDisk()
        
        // 4. Emit socket event
        SocketService.shared.deleteRegistry(id: id.uuidString)
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
    
    func removeItem(_ productId: String) {
        guard var registry = currentRegistry else { return }
        registry.items.removeAll { $0.id == productId }
        currentRegistry = registry
        syncRegistry(registry)
    }
    
    func toggleUpvote(_ productId: String) {
        guard var registry = currentRegistry else { return }
        guard let index = registry.items.firstIndex(where: { $0.id == productId }) else { return }
        
        let userName = SocketService.shared.currentDisplayName
        var item = registry.items[index]
        
        if item.upvotedBy.contains(userName) {
            item.upvotedBy.removeAll { $0 == userName }
        } else {
            item.upvotedBy.append(userName)
        }
        
        registry.items[index] = item
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
                "upvotedBy": item.upvotedBy
            ]
        }
        
        let registryDict: [String: Any] = [
            "id": registry.id.uuidString,
            "firstName": registry.firstName,
            "lastName": registry.lastName,
            "event": registry.event.rawValue,
            "date": registry.date.timeIntervalSince1970,
            "budget": registry.budget ?? "",
            "items": itemsDict,
            "collaboratorNames": registry.collaboratorNames
        ]
        
        SocketService.shared.syncRegistry(id: registry.id.uuidString, data: registryDict)
    }
    
    private func applyRemoteUpdate(_ dict: [String: Any]) {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        // Ignore remote updates for registries that were deleted locally
        if deletedRegistryIds.contains(id) {
            print("📦 Ignoring remote update for recently deleted registry \(idString)")
            return
        }
        
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
                    
                    return RegistryItem(
                        id: itemId,
                        title: title,
                        price: price,
                        imageUrl: itemDict["imageUrl"] as? String,
                        quantity: qty,
                        upvotedBy: itemDict["upvotedBy"] as? [String] ?? []
                    )
                }
            }
            
            // Update metadata if available
            if let eventRaw = dict["event"] as? String, let event = RegistryEvent(rawValue: eventRaw) {
                registry.event = event
            }
            if let timeInterval = dict["date"] as? TimeInterval {
                registry.date = Date(timeIntervalSince1970: timeInterval)
            }
            if let budget = dict["budget"] as? String {
                registry.budget = budget
            }
            if let collaborators = dict["collaboratorNames"] as? [String] {
                registry.collaboratorNames = collaborators
            }
            
            registries[index] = registry
            if activeRegistryId == id {
                currentRegistry = registry
            }
            saveToDisk()
        } else {
            // New registry we didn't have locally (e.g. joined via invite on another device)
            if let registry = parseRegistry(from: dict) {
                // If it is a shared registry, only add it if we are a collaborator on it
                let isShared = registry.lastName.contains("Shared") || !registry.collaboratorNames.isEmpty
                if isShared {
                    let myName = SocketService.shared.currentDisplayName.lowercased()
                    let isMeCollaborator = registry.collaboratorNames.contains { $0.lowercased() == myName }
                    if !isMeCollaborator {
                        print("⚠️ Skipping remote update for registry \(idString) since we are not a collaborator on it.")
                        return
                    }
                }
                
                registries.append(registry)
                saveToDisk()
            }
        }
    }
    
    private func applyBulkRemoteUpdate(_ array: [[String: Any]]) {
        for dict in array {
            self.applyRemoteUpdate(dict)
        }
    }
    
    private func parseRegistry(from dict: [String: Any]) -> Registry? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let firstName = dict["firstName"] as? String,
              let lastName = dict["lastName"] as? String else { return nil }
        
        var items: [RegistryItem] = []
        if let itemsArray = dict["items"] as? [[String: Any]] {
            items = itemsArray.compactMap { itemDict -> RegistryItem? in
                guard let itemId = itemDict["id"] as? String,
                      let title = itemDict["title"] as? String,
                      let price = itemDict["price"] as? Double,
                      let qty = itemDict["quantity"] as? Int else { return nil }
                
                return RegistryItem(
                    id: itemId,
                    title: title,
                    price: price,
                    imageUrl: itemDict["imageUrl"] as? String,
                    quantity: qty,
                    upvotedBy: itemDict["upvotedBy"] as? [String] ?? []
                )
            }
        }
        
        let eventRaw = dict["event"] as? String ?? ""
        let event = RegistryEvent(rawValue: eventRaw) ?? .wedding
        let date = (dict["date"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let budget = dict["budget"] as? String
        let collaborators = dict["collaboratorNames"] as? [String] ?? []
        
        return Registry(
            id: id,
            firstName: firstName,
            lastName: lastName,
            event: event,
            date: date,
            budget: budget,
            items: items,
            collaboratorNames: collaborators
        )
    }
    
    func quantity(for registryItem: RegistryItem) -> Int {
        currentRegistry?.items.first(where: { $0.id == registryItem.id })?.quantity ?? 0
    }
}
