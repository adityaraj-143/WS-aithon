//
//  RegistryDetailViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RegistryDetailViewModel: ObservableObject {
    @Published var suggestedProducts: [ProductItem] = []
    @Published var isLoading = false
    
    private var hasLoaded = false
    
    func fetchSuggestedProducts() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        
        do {
            let dtos: [ProductItemDTO] = try await APIClient.shared.request(Endpoint.products())
            self.suggestedProducts = dtos.map { ProductItem(from: $0) }
        } catch {
            print("Failed to fetch suggested products: \(error)")
        }
        
        isLoading = false
    }
}
