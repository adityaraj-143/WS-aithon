//
//  ScoredProduct.swift
//  WSHackathonApp
//

import Foundation

/// A product paired with its cosine similarity score against a search prompt.
struct ScoredProduct: Identifiable {
    var id: String { product.id }
    let product: ProductItem
    /// Cosine similarity in [0, 1] — higher = more semantically similar to the query.
    let score: Double

    /// Human-readable match percentage (0–100)
    var matchPercent: Int {
        Int((score * 100).rounded())
    }
}

/// A curated registry plan built from semantically matched products within a budget.
struct RegistryPlan {
    let items: [ScoredProduct]
    let totalCost: Double
    let budget: Double
    let coverageScore: Double
    let missingEssentials: [String]
    let budgetBreakdown: RegistryBudgetBreakdown

    var remainingBudget: Double {
        max(0, budget - totalCost)
    }

    var isWithinBudget: Bool {
        totalCost <= budget
    }

    var isEmpty: Bool {
        items.isEmpty
    }
}

struct RegistryBudgetBreakdown {
    let essentialsCost: Double
    let optionalCost: Double
}

struct PlannedRegistryResponse {
    let intent: RegistryPromptIntent
    let browseProducts: [ScoredProduct]
    let registryPlan: RegistryPlan
}

struct RegistryConversationState {
    var budget: Double?
    var eventType: String?
    var styleHints: Set<String>
    var ownedKeywords: Set<String>
    var excludedKeywords: Set<String>

    static var empty: RegistryConversationState {
        RegistryConversationState(
            budget: nil,
            eventType: nil,
            styleHints: [],
            ownedKeywords: [],
            excludedKeywords: []
        )
    }

    mutating func merge(intent: RegistryPromptIntent) {
        if let budget = intent.budget {
            self.budget = budget
        }
        if let eventType = intent.eventType {
            self.eventType = eventType
        }
        styleHints.formUnion(intent.styleHints)
        ownedKeywords.formUnion(intent.ownedKeywords)
        excludedKeywords.formUnion(intent.excludedKeywords)
    }
}
