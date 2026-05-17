//
//  CreateRegistryViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import Combine

@MainActor
final class CreateRegistryViewModel: ObservableObject {
    @Published var registryName: String = ""
    @Published var selectedEvent: RegistryEvent = .wedding
    @Published var date: Date = Date()
    @Published var budget: String = ""
    @Published var aiPrompt: String = ""
    
    @Published var isAIEnabled: Bool = false
    
    var isValid: Bool {
        !registryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var normalizedBudget: String? {
        let trimmed = budget.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var effectiveRegistryName: String {
        let trimmed = registryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "My Registry" : trimmed
    }

    var planningContext: RegistryPlanningContext {
        RegistryPlanningContext(
            registryName: effectiveRegistryName,
            event: selectedEvent,
            date: date,
            budget: normalizedBudget,
            aiPrompt: aiPrompt
        )
    }
}
