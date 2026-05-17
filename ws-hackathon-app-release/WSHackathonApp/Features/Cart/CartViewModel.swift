import Foundation
import Combine

enum CartSectionType: String, Codable {
    case registry
    case personal
}

struct CartSection: Identifiable {
    let id: String // registryId or "personal"
    let type: CartSectionType
    let title: String
    let registryId: String?
    let eventDate: Date?
    var isExpanded: Bool
    let items: [CartItem]
    
    var totalAmount: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
}

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var items: [CartItem] = []
    @Published private(set) var sections: [CartSection] = []
    @Published var expandedSections: Set<String> = []
    
    private var cancellable: AnyCancellable?
    private var repository: CartRepository?
    private var hasInitializedExpandedState = false
    
    func bind(repository: CartRepository) {
        self.repository = repository
        self.items = repository.items
        
        cancellable = repository.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedItems in
                guard let self = self else { return }
                self.items = updatedItems
                self.rebuildSections()
            }
            
        rebuildSections()
    }
    
    private func rebuildSections() {
        var registryGroups: [String: [CartItem]] = [:]
        var personalItems: [CartItem] = []
        
        for item in items {
            if let registryId = item.registryId {
                registryGroups[registryId, default: []].append(item)
            } else {
                personalItems.append(item)
            }
        }
        
        var newSections: [CartSection] = []
        
        // 1. Build registry sections
        for (registryId, groupItems) in registryGroups {
            let firstItem = groupItems.first!
            let title = firstItem.registryName ?? "Registry"
            let date = firstItem.registryEventDate
            
            let isExpanded = expandedSections.contains(registryId)
            
            let section = CartSection(
                id: registryId,
                type: .registry,
                title: title,
                registryId: registryId,
                eventDate: date,
                isExpanded: isExpanded,
                items: groupItems
            )
            newSections.append(section)
        }
        
        // Sort registry sections by title for consistent order
        newSections.sort { $0.title < $1.title }
        
        // 2. Build personal section
        if !personalItems.isEmpty {
            let isExpanded = expandedSections.contains("personal")
            let personalSection = CartSection(
                id: "personal",
                type: .personal,
                title: "Personal Cart",
                registryId: nil,
                eventDate: nil,
                isExpanded: isExpanded,
                items: personalItems
            )
            newSections.append(personalSection)
        }
        
        // 3. First section expanded by default on initial layout
        if !hasInitializedExpandedState && !newSections.isEmpty {
            hasInitializedExpandedState = true
            let firstSectionId = newSections[0].id
            expandedSections.insert(firstSectionId)
            newSections[0] = CartSection(
                id: newSections[0].id,
                type: newSections[0].type,
                title: newSections[0].title,
                registryId: newSections[0].registryId,
                eventDate: newSections[0].eventDate,
                isExpanded: true,
                items: newSections[0].items
            )
        }
        
        self.sections = newSections
    }
    
    func toggleSection(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
        rebuildSections()
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
