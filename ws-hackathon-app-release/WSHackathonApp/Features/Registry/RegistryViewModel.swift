//
//  RegistryViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RegistryViewModel: ObservableObject {
    @Published private(set) var registries: [Registry] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Bind Repository
    
    func bind(repository: RegistryRepository) {
        repository.$registries
            .receive(on: RunLoop.main)
            .assign(to: &$registries)
    }
    
    // MARK: - Computed
    
    var hasRegistry: Bool {
        !registries.isEmpty
    }
    
    // MARK: - Instructions
    
    var instructions: [RegistryInstruction] {
        [
            RegistryInstruction(
                title: AppStrings.Registry.exclusiveProduct,
                description: AppStrings.Registry.exclusiveProductsDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.expertAdvice,
                description: AppStrings.Registry.expertAdviceDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.discountTitle,
                description: AppStrings.Registry.discountDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.inStoreTitle,
                description: AppStrings.Registry.instStoreDesc
            )
        ]
    }
    
    // MARK: - Actions
    
    func deleteRegistry(_ registry: Registry, using repository: RegistryRepository) {
        repository.deleteRegistry(id: registry.id)
    }
}
