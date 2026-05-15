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
