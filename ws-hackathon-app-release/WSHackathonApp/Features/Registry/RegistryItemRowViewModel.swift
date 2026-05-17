//
//  RegistryItemRowViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class RegistryItemRowViewModel: ObservableObject {
    
    private var latestItem: RegistryItem {
        registryRepo.currentRegistry?.items.first(where: { $0.id == itemId }) ?? initialItem
    }
    
    private let initialItem: RegistryItem
    private let itemId: String
    private let registryRepo: RegistryRepository
    private let cartRepo: CartRepository
    private let tabBarVM: WSTabBarViewModel

    private var cancellables = Set<AnyCancellable>()

    init(item: RegistryItem,
         registryRepo: RegistryRepository,
         cartRepo: CartRepository,
         tabbarVM: WSTabBarViewModel) {
        self.initialItem = item
        self.itemId = item.id
        self.registryRepo = registryRepo
        self.cartRepo = cartRepo
        self.tabBarVM = tabbarVM
        
        // Listen for repository changes to refresh the UI
        registryRepo.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        cartRepo.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Display
    
    var title: String { latestItem.title }
    
    var priceText: String {
        "$\(latestItem.price, default: "%.2f")"
    }
    
    var quantityText: String {
        "\(latestItem.quantity)"
    }
    
    var imageURL: URL? {
        guard let url = latestItem.imageUrl else { return nil }
        return URL(string: AppConstants.API.imageBasePath + url)
    }
    
    var isInCart: Bool {
        let registryId = registryRepo.currentRegistry?.id.uuidString ?? ""
        let cartItemId = "\(itemId)_\(registryId)"
        return cartRepo.items.contains(where: { $0.id == cartItemId })
    }
    
    // MARK: - Actions
    
    func increaseQty() {
        registryRepo.increaseQty(itemId)
    }
    
    func decreaseQty() {
        registryRepo.decreaseQty(itemId)
    }
    
    func removeItem() {
        registryRepo.removeItem(itemId)
    }
    
    var upvoteCount: Int {
        latestItem.upvotedBy.count
    }
    
    var isUpvoted: Bool {
        latestItem.upvotedBy.contains(SocketService.shared.currentDisplayName)
    }
    
    var upvotedByText: String {
        if latestItem.upvotedBy.isEmpty { return "" }
        if latestItem.upvotedBy.count == 1 {
            return "Liked by \(latestItem.upvotedBy[0])"
        }
        return "Liked by \(latestItem.upvotedBy[0]) and \(latestItem.upvotedBy.count - 1) others"
    }
    
    func toggleUpvote() {
        registryRepo.toggleUpvote(itemId)
    }
    
    func addToCart() {
        let registry = registryRepo.currentRegistry
        let registryId = registry?.id.uuidString
        let registryName = registry?.displayName
        let registryEventDate = registry?.date
        
        // Create a basic ProductItem to add to cart
        let product = ProductItem(
            id: latestItem.id,
            title: latestItem.title,
            price: latestItem.price,
            retailPrice: nil,
            path: latestItem.imageUrl,
            color: nil,
            brand: nil,
            shortDescription: nil,
            availability: nil,
            deliveryEstimate: nil,
            material: nil,
            collection: nil,
            semanticDescription: nil,
            eventTags: [],
            slotHints: [],
            styleTags: [],
            settingTags: [],
            essentialForEvents: [],
            productType: nil,
            canGiftWrap: false,
            isFreeShipping: false
        )
        cartRepo.add(
            product: product,
            quantity: latestItem.quantity,
            registryId: registryId,
            registryName: registryName,
            registryEventDate: registryEventDate
        )
    }
    
    func removeFromCart() {
        let registryId = registryRepo.currentRegistry?.id.uuidString ?? ""
        let cartItemId = "\(itemId)_\(registryId)"
        cartRepo.removeItemCompletely(productId: cartItemId)
    }
}
