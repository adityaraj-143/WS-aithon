//
//  RegistryPlanBuilder.swift
//  WSHackathonApp
//
//  Selects a budget-aware subset of semantically matched products.
//  Strategy: greedy by similarity score descending (highest relevance first).
//  Items are added while the running total stays within budget.
//

import Foundation

struct RegistryPlanBuilder {

    // MARK: - Build

    /// Builds a `RegistryPlan` from a ranked list of candidates.
    ///
    /// - Parameters:
    ///   - candidates: Products already ranked by cosine similarity (highest first).
    ///   - intent: Parsed intent containing optional budget.
    /// - Returns: A `RegistryPlan` with selected items, cost summary, and remaining budget.
    func build(from candidates: [ScoredProduct], intent: RegistryPromptIntent) -> RegistryPlan {
        guard let budget = intent.budget else {
            // No budget: return all candidates as-is (no financial filtering)
            let total = candidates.compactMap(\.product.price).reduce(0, +)
            return RegistryPlan(
                items: candidates,
                totalCost: total,
                budget: .infinity
            )
        }

        return buildWithBudget(candidates: candidates, budget: budget)
    }

    // MARK: - Private

    private func buildWithBudget(candidates: [ScoredProduct], budget: Double) -> RegistryPlan {
        var selected: [ScoredProduct] = []
        var runningTotal: Double = 0

        for candidate in candidates {
            let price = candidate.product.price ?? 0

            // If item is free or fits in remaining budget, include it
            if runningTotal + price <= budget {
                selected.append(candidate)
                runningTotal += price
            }
            // If it doesn't fit, we keep trying cheaper items further down the ranked list
        }

        return RegistryPlan(
            items: selected,
            totalCost: runningTotal,
            budget: budget
        )
    }
}
