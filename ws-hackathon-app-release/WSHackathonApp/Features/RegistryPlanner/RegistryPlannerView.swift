//
//  RegistryPlannerView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryPlannerView: View {

    @EnvironmentObject var registryRepo: RegistryRepository
    @StateObject private var viewModel = RegistryPlannerViewModel()

    let productDTOs: [ProductItemDTO]
    let planningContext: RegistryPlanningContext?
    var onClose: (() -> Void)? = nil
    var onAddAllComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPromptFocused: Bool
    @State private var hasTriggeredInitialSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    promptBar
                    stateContent
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI REGISTRY STUDIO")
                        .font(.system(size: 12, weight: .bold))
                        .kerning(2)
                        .foregroundColor(.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { closePlanner() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .task {
            if let planningContext {
                viewModel.configureInitialPrompt(planningContext.combinedPrompt)
            }
        }
        .task(id: productDTOs.count) {
            viewModel.buildIndex(dtos: productDTOs)
        }
        .onChange(of: viewModel.indexReady) {
            triggerInitialSearchIfNeeded()
        }
    }

    private var promptBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.brandPrimary)
                    .font(.system(size: 14))

                TextField(
                    "Minimal and cozy wedding regi...",
                    text: $viewModel.promptText,
                    axis: .vertical
                )
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1...4)
                .focused($isPromptFocused)
                .submitLabel(.search)
                .onSubmit { runSearch() }

                Button(action: runSearch) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .disabled(viewModel.promptText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.state.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            idlePlaceholder
        case .indexing:
            loadingView(message: "Building on-device AI index…")
        case .searching:
            loadingView(message: "Finding your perfect products…")
        case .results(let response):
            RegistryPlanResultView(
                response: response,
                canAddToRegistry: registryRepo.isActiveRegistry,
                onAddAll: { addAllToRegistry(plan: response.registryPlan) },
                onAddItem: { registryRepo.addProduct($0) },
                planningContext: planningContext
            )
        case .noResults:
            noResultsView
        case .error(let msg):
            errorView(message: msg)
        }
    }

    private var idlePlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Describe Your Perfect Registry")
                .font(.system(size: 24, weight: .bold, design: .serif))
            Text("Tell us your style, event, and budget.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func loadingView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.4)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("No products matched your prompt.")
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(message)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    private func runSearch() {
        isPromptFocused = false
        viewModel.search()
    }

    private func triggerInitialSearchIfNeeded() {
        guard planningContext != nil else { return }
        guard viewModel.indexReady else { return }
        guard !hasTriggeredInitialSearch else { return }
        guard !viewModel.promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        hasTriggeredInitialSearch = true
        runSearch()
    }

    private func addAllToRegistry(plan: RegistryPlan) {
        guard registryRepo.isActiveRegistry else { return }
        for scored in plan.items {
            registryRepo.addProduct(scored.product)
        }
        onAddAllComplete?()
        closePlanner()
    }

    private func closePlanner() {
        onClose?()
        dismiss()
    }
}
