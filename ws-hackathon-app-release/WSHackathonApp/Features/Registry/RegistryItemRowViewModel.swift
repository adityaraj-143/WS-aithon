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
    
    let item: RegistryItem
    
    private let registryRepo: RegistryRepository
    private let cartRepo: CartRepository
    private let tabBarVM: WSTabBarViewModel

    init(item: RegistryItem,
         registryRepo: RegistryRepository,
         cartRepo: CartRepository,
         tabbarVM: WSTabBarViewModel) {
        self.item = item
        self.registryRepo = registryRepo
        self.cartRepo = cartRepo
        self.tabBarVM = tabbarVM
    }
    
    // MARK: - Display
    
    var title: String { item.title }
    
    var priceText: String {
        "$\(item.price, default: "%.2f")"
    }
    
    var quantityText: String {
        "\(registryRepo.quantity(for: item))"
    }
    
    var imageURL: URL? {
        guard let url = item.imageUrl else { return nil }
        return URL(string: AppConstants.API.imageBasePath + url)
    }
    
    var upvotersCount: Int {
        registryRepo.currentRegistry?.items.first(where: { $0.id == item.id })?.upvoters.count ?? 0
    }
    
    var downvotersCount: Int {
        registryRepo.currentRegistry?.items.first(where: { $0.id == item.id })?.downvoters.count ?? 0
    }
    
    var isUpvotedByMe: Bool {
        registryRepo.currentRegistry?.items.first(where: { $0.id == item.id })?.upvoters.contains(SocketService.shared.currentUserId) ?? false
    }
    
    var isDownvotedByMe: Bool {
        registryRepo.currentRegistry?.items.first(where: { $0.id == item.id })?.downvoters.contains(SocketService.shared.currentUserId) ?? false
    }
    
    // MARK: - Actions
    
    func increaseQty() {
        registryRepo.increaseQty(item.id)
    }
    
    func decreaseQty() {
        registryRepo.decreaseQty(item.id)
    }
    
    func removeItem() {
        registryRepo.removeItem(item.id)
    }
    
    func upvoteItem() {
        registryRepo.upvoteItem(item.id)
    }
    
    func downvoteItem() {
        registryRepo.downvoteItem(item.id)
    }
}
