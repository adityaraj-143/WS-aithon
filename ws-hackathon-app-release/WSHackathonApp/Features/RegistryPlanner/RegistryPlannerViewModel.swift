//
//  RegistryPlannerViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

enum PlannerState {
    case idle
    case indexing        // Building the NLEmbedding index in background
    case searching       // Running cosine similarity search
    case results(PlannedRegistryResponse)
    case noResults       // Search returned nothing above threshold
    case error(String)

    var isLoading: Bool {
        switch self {
        case .indexing, .searching: return true
        default: return false
        }
    }
}

@MainActor
final class RegistryPlannerViewModel: ObservableObject {

    // MARK: - Published

    @Published var promptText: String = ""
    @Published var state: PlannerState = .idle
    @Published var indexReady: Bool = false
    @Published private(set) var initialSearchPerformed = false

    // MARK: - Dependencies

    nonisolated private let planner: RegistryPlannerService

    init() {
        self.planner = RegistryPlannerService()
    }

    // MARK: - Index Bootstrap

    /// Call once when the view appears, passing the raw DTOs fetched from /skus.
    /// Indexing runs on a detached background task so it never blocks the main thread.
    func buildIndex(dtos: [ProductItemDTO]) {
        guard !indexReady else { return }
        guard !dtos.isEmpty else {
            state = .error("Product catalog is still loading. Open Home first or wait for products to finish loading.")
            return
        }
        state = .indexing

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.planner.buildIndex(dtos: dtos)
            await MainActor.run {
                self.indexReady = self.planner.hasIndex
                self.state = self.planner.hasIndex ? .idle : .error("Unable to build the AI product index on this device.")
            }
        }
    }

    // MARK: - Search

    func search() {
        let query = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard indexReady else {
            state = .error("Products are still loading. Please wait a moment.")
            return
        }

        state = .searching

        Task {
            let response = await Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else {
                    return PlannedRegistryResponse(
                        intent: RegistryPromptIntent(
                            rawPrompt: query,
                            budget: nil,
                            eventType: nil,
                            styleHints: [],
                            ownedKeywords: [],
                            excludedKeywords: []
                        ),
                        browseProducts: [],
                        registryPlan: RegistryPlan(
                            items: [],
                            totalCost: 0,
                            budget: .infinity,
                            coverageScore: 0,
                            missingEssentials: [],
                            budgetBreakdown: RegistryBudgetBreakdown(essentialsCost: 0, optionalCost: 0)
                        )
                    )
                }

                return self.planner.plan(prompt: query, topK: 20, minScore: 0.1)
            }.value

            if response.browseProducts.isEmpty && response.registryPlan.isEmpty {
                state = .noResults
            } else {
                initialSearchPerformed = true
                state = .results(response)
            }
        }
    }

    func configureInitialPrompt(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        promptText = trimmed
    }

    // MARK: - Clear

    func clear() {
        promptText = ""
        planner.resetConversation()
        state = .idle
    }

    // MARK: - Convenience

    var currentResponse: PlannedRegistryResponse? {
        if case .results(let response) = state { return response }
        return nil
    }

    var currentPlan: RegistryPlan? {
        currentResponse?.registryPlan
    }

    var parsedIntent: RegistryPromptIntent? {
        let query = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        return PromptParser().parse(query)
    }
}
