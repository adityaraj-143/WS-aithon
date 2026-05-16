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

    func build(from candidates: [ScoredProduct], intent: RegistryPromptIntent) -> RegistryPlan {
        var state = RegistryConversationState.empty
        state.merge(intent: intent)
        return build(from: candidates, intent: intent, state: state)
    }

    func build(
        from candidates: [ScoredProduct],
        intent: RegistryPromptIntent,
        state: RegistryConversationState
    ) -> RegistryPlan {
        let budget = state.budget ?? intent.budget ?? .infinity
        let filteredCandidates = filter(candidates: candidates, state: state)
        let template = RegistryEventTemplate.template(for: state.eventType ?? intent.eventType)
        let ownedSlots = identifyOwnedSlots(in: template.requiredSlots, state: state)

        var selectedIDs = Set<String>()
        var selected: [ScoredProduct] = []
        var essentialsCost: Double = 0
        var optionalCost: Double = 0
        var runningTotal: Double = 0
        var missingEssentials: [String] = []

        for slot in template.requiredSlots where !ownedSlots.contains(slot) {
            guard let match = bestCandidate(
                for: slot,
                in: filteredCandidates,
                selectedIDs: selectedIDs,
                state: state,
                remainingBudget: budget - runningTotal
            ) else {
                missingEssentials.append(slot)
                continue
            }

            selected.append(match)
            selectedIDs.insert(match.id)
            let price = match.product.price ?? 0
            runningTotal += price
            essentialsCost += price
        }

        for slot in template.optionalSlots {
            let sortedOptional = filteredCandidates
                .filter { !selectedIDs.contains($0.id) }
                .filter { matches(slot: slot, product: $0.product) }
                .sorted { adjustedScore(for: $0, slot: slot, state: state) > adjustedScore(for: $1, slot: slot, state: state) }

            if let candidate = sortedOptional.first(where: { runningTotal + ($0.product.price ?? 0) <= budget }) {
                let price = candidate.product.price ?? 0
                selected.append(candidate)
                selectedIDs.insert(candidate.id)
                runningTotal += price
                optionalCost += price
            }
        }

        let generalCandidates = filteredCandidates
            .filter { !selectedIDs.contains($0.id) }
            .sorted { adjustedScore(for: $0, slot: "general", state: state) > adjustedScore(for: $1, slot: "general", state: state) }

        for candidate in generalCandidates {
            let price = candidate.product.price ?? 0
            if runningTotal + price > budget {
                continue
            }

            selected.append(candidate)
            selectedIDs.insert(candidate.id)
            runningTotal += price
            optionalCost += price
        }

        let coverageScore: Double
        if template.requiredSlots.isEmpty {
            coverageScore = selected.isEmpty ? 0 : 1
        } else {
            let satisfiedRequired = template.requiredSlots.count - missingEssentials.count
            coverageScore = Double(satisfiedRequired) / Double(template.requiredSlots.count)
        }

        return RegistryPlan(
            items: selected,
            totalCost: runningTotal,
            budget: budget,
            coverageScore: coverageScore,
            missingEssentials: missingEssentials,
            budgetBreakdown: RegistryBudgetBreakdown(
                essentialsCost: essentialsCost,
                optionalCost: optionalCost
            )
        )
    }

    private func filter(candidates: [ScoredProduct], state: RegistryConversationState) -> [ScoredProduct] {
        candidates.filter { candidate in
            !state.ownedKeywords.contains(where: { matches(keyword: $0, product: candidate.product) }) &&
            !state.excludedKeywords.contains(where: { matches(keyword: $0, product: candidate.product) })
        }
    }

    private func identifyOwnedSlots(in requiredSlots: [String], state: RegistryConversationState) -> Set<String> {
        Set(requiredSlots.filter { slot in
            state.ownedKeywords.contains { owned in
                owned.contains(slot.replacingOccurrences(of: "-", with: " ")) ||
                slot.contains(owned.replacingOccurrences(of: " ", with: "-"))
            }
        })
    }

    private func bestCandidate(
        for slot: String,
        in candidates: [ScoredProduct],
        selectedIDs: Set<String>,
        state: RegistryConversationState,
        remainingBudget: Double
    ) -> ScoredProduct? {
        candidates
            .filter { !selectedIDs.contains($0.id) }
            .filter { matches(slot: slot, product: $0.product) }
            .filter { ($0.product.price ?? 0) <= remainingBudget }
            .sorted { adjustedScore(for: $0, slot: slot, state: state) > adjustedScore(for: $1, slot: slot, state: state) }
            .first
    }

    private func adjustedScore(for candidate: ScoredProduct, slot: String, state: RegistryConversationState) -> Double {
        let slotBoost = matches(slot: slot, product: candidate.product) ? 0.25 : 0
        let eventBoost = state.eventType.map { event in
            let searchable = [
                candidate.product.title,
                candidate.product.collection ?? "",
                candidate.product.shortDescription ?? "",
                candidate.product.semanticDescription ?? ""
            ] + candidate.product.eventTags + candidate.product.essentialForEvents
            return searchable.contains { normalizeToken($0).contains(normalizeToken(event)) } ? 0.15 : 0
        } ?? 0
        let styleBoost = state.styleHints.contains { style in
            let searchable = [
                candidate.product.title,
                candidate.product.collection ?? "",
                candidate.product.material ?? "",
                candidate.product.shortDescription ?? "",
                candidate.product.semanticDescription ?? ""
            ] + candidate.product.styleTags
            return searchable.contains { normalizeToken($0).contains(normalizeToken(style)) }
        } ? 0.1 : 0

        let price = candidate.product.price ?? 0
        let affordabilityBoost: Double
        switch price {
        case ..<50: affordabilityBoost = 0.12
        case ..<150: affordabilityBoost = 0.08
        case ..<300: affordabilityBoost = 0.04
        default: affordabilityBoost = 0
        }

        return candidate.score + slotBoost + eventBoost + styleBoost + affordabilityBoost
    }

    private func matches(slot: String, product: ProductItem) -> Bool {
        let normalizedSlot = normalizeToken(slot)
        var values = [
            product.title,
            product.shortDescription ?? "",
            product.semanticDescription ?? "",
            product.collection ?? "",
            product.brand ?? "",
            product.material ?? "",
            product.productType ?? "",
            product.color ?? ""
        ]
        values.append(contentsOf: product.slotHints)
        values.append(contentsOf: product.settingTags)
        values.append(contentsOf: product.eventTags)
        values.append(contentsOf: product.styleTags)

        return values.contains { normalizeToken($0).contains(normalizedSlot) }
    }

    private func matches(keyword: String, product: ProductItem) -> Bool {
        let normalizedKeyword = normalizeToken(keyword)
        var searchable = [
            product.title,
            product.shortDescription ?? "",
            product.semanticDescription ?? "",
            product.collection ?? "",
            product.brand ?? "",
            product.material ?? "",
            product.productType ?? ""
        ]
        searchable.append(contentsOf: product.slotHints)
        searchable.append(contentsOf: product.settingTags)
        searchable.append(contentsOf: product.eventTags)
        searchable.append(contentsOf: product.styleTags)

        return searchable.contains { normalizeToken($0).contains(normalizedKeyword) }
    }

    private func normalizeToken(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }
}
