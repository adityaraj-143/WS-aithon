import Foundation
import Combine

/**
 * RegistryCartSyncManager
 * 
 * An isolated real-time collaborative cart coordinator that observes local cart changes
 * and synchronizes them with collaborators using isolated socket events.
 * It prevents infinite sync loops and duplicate broadcasts through cache checks.
 */
@MainActor
final class RegistryCartSyncManager: ObservableObject {
    static let shared = RegistryCartSyncManager()
    
    private var cartRepository: CartRepository?
    private var registryRepository: RegistryRepository?
    private var cancellables = Set<AnyCancellable>()
    private var lastSyncedRegistryCarts: [String: [CartItem]] = [:]
    private var isReconciling = false
    
    private init() {
        setupSocketListeners()
    }
    
    /**
     * Binds the repositories and starts listening for local cart mutations.
     */
    func bind(cartRepository: CartRepository, registryRepository: RegistryRepository) {
        // Guard to avoid duplicate binding setup
        guard self.cartRepository == nil else { return }
        
        self.cartRepository = cartRepository
        self.registryRepository = registryRepository
        
        // Listen to local cart changes reactively via Combine
        cartRepository.$items
            .sink { [weak self] newItems in
                guard let self = self else { return }
                self.syncLocalCartItems(newItems)
            }
            .store(in: &cancellables)
    }
    
    /**
     * Setup listener for incoming collaborative cart sync socket broadcasts
     */
    private func setupSocketListeners() {
        NotificationCenter.default.addObserver(
            forName: .didReceiveRegistryCartSync,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let dict = notification.object as? [String: Any] else { return }
            self.reconcileIncomingCartSync(dict)
        }
    }
    
    /**
     * Filters, detects, and synchronizes local shared registry cart state modifications
     */
    private func syncLocalCartItems(_ newItems: [CartItem]) {
        guard !isReconciling,
              let registryRepo = registryRepository,
              SocketService.shared.isConnected else { return }
        
        // Filter out items that belong to registries (non-nil registryId)
        let registryItems = newItems.filter { $0.registryId != nil }
        
        let grouped = Dictionary(grouping: registryItems, by: { $0.registryId! })
        
        // Gather all relevant registry IDs (current and previous) to detect deletions
        var allRegistryIds = Set(grouped.keys)
        for oldRegId in lastSyncedRegistryCarts.keys {
            allRegistryIds.insert(oldRegId)
        }
        
        for regId in allRegistryIds {
            let currentItems = grouped[regId] ?? []
            let previousItems = lastSyncedRegistryCarts[regId] ?? []
            
            // Compare the items to avoid infinite loop or redundant broadcasts
            if currentItems != previousItems {
                lastSyncedRegistryCarts[regId] = currentItems
                emitCartSync(registryId: regId, items: currentItems)
            }
        }
    }
    
    /**
     * Serializes and emits the shared registry cart state to the socket server
     */
    private func emitCartSync(registryId: String, items: [CartItem]) {
        let serializedItems = items.map { item -> [String: Any] in
            var dict: [String: Any] = [
                "id": item.id,
                "title": item.title,
                "price": item.price,
                "quantity": item.quantity
            ]
            if let path = item.path { dict["path"] = path }
            if let regId = item.registryId { dict["registryId"] = regId }
            if let regName = item.registryName { dict["registryName"] = regName }
            if let regDate = item.registryEventDate {
                dict["registryEventDate"] = regDate.timeIntervalSince1970
            }
            return dict
        }
        
        let payload: [String: Any] = [
            "registryId": registryId,
            "cartItems": serializedItems,
            "senderId": SocketService.shared.currentUserId
        ]
        
        print("🛒 Emitting cart sync to server for registry \(registryId) with \(items.count) items")
        SocketService.shared.emitCartSync(payload: payload)
    }
    
    /**
     * Reconciles incoming remote collaborative cart sync state updates
     */
    private func reconcileIncomingCartSync(_ dict: [String: Any]) {
        guard let registryId = dict["registryId"] as? String,
              let cartItemsArray = dict["cartItems"] as? [[String: Any]],
              let cartRepo = cartRepository else { return }
        
        // Avoid self-sync loop if we initiated this broadcast
        if let senderId = dict["senderId"] as? String,
           senderId == SocketService.shared.currentUserId {
            return
        }
        
        print("🛒 Reconciling incoming collaborative cart state for registry \(registryId)")
        isReconciling = true
        
        // Parse incoming items
        let incomingItems = cartItemsArray.compactMap { itemDict -> CartItem? in
            guard let id = itemDict["id"] as? String,
                  let title = itemDict["title"] as? String,
                  let price = itemDict["price"] as? Double,
                  let quantity = itemDict["quantity"] as? Int else { return nil }
            
            let path = itemDict["path"] as? String
            let regId = itemDict["registryId"] as? String
            let regName = itemDict["registryName"] as? String
            
            var regDate: Date? = nil
            if let regDateTimeVal = itemDict["registryEventDate"] as? Double {
                regDate = Date(timeIntervalSince1970: regDateTimeVal)
            }
            
            return CartItem(
                id: id,
                title: title,
                price: price,
                path: path,
                quantity: quantity,
                registryId: regId,
                registryName: regName,
                registryEventDate: regDate
            )
        }
        
        // Perform atomic update: replace only items for this registry
        var currentLocalItems = cartRepo.items
        currentLocalItems.removeAll(where: { $0.registryId == registryId })
        currentLocalItems.append(contentsOf: incomingItems)
        
        // Cache the latest synced items to prevent outgoing sync echo
        lastSyncedRegistryCarts[registryId] = incomingItems
        
        // Apply back to the main repository
        cartRepo.setItems(currentLocalItems)
        isReconciling = false
    }
}
