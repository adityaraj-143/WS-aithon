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
    case results(RegistryPlan)
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

    // MARK: - Dependencies

    private let vectorStore = ProductVectorStore()
    private let parser = PromptParser()
    private let planBuilder = RegistryPlanBuilder()

    // MARK: - Index Bootstrap

    /// Call once when the view appears, passing the raw DTOs fetched from /skus.
    /// Indexing runs on a detached background task so it never blocks the main thread.
    func buildIndex(dtos: [ProductItemDTO]) {
        guard !indexReady else { return }
        state = .indexing

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self.vectorStore.index(dtos: dtos)
            await MainActor.run {
                self.indexReady = self.vectorStore.hasIndex
                self.state = .idle
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
            // Run the CPU-bound search off the main thread
            let (plan) = await Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else {
                    return RegistryPlan(
                        items: [],
                        totalCost: 0,
                        budget: .infinity,
                        coverageScore: 0,
                        missingEssentials: [],
                        budgetBreakdown: RegistryBudgetBreakdown(essentialsCost: 0, optionalCost: 0)
                    )
                }

                let intent = self.parser.parse(query)
                let candidates = self.vectorStore.search(prompt: query, topK: 20, minScore: 0.1)
                return self.planBuilder.build(from: candidates, intent: intent)
            }.value

            if plan.isEmpty {
                state = .noResults
            } else {
                state = .results(plan)
            }
        }
    }

    // MARK: - Clear

    func clear() {
        promptText = ""
        state = .idle
    }

    // MARK: - Convenience

    var currentPlan: RegistryPlan? {
        if case .results(let plan) = state { return plan }
        return nil
    }

    var parsedIntent: RegistryPromptIntent? {
        let query = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        return parser.parse(query)
    }
}
