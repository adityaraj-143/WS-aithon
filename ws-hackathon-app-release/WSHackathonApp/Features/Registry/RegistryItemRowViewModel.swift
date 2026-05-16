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
}
