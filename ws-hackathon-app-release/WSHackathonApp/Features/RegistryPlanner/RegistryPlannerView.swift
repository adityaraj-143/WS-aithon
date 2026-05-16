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
                Color(.systemGray6).ignoresSafeArea()

                VStack(spacing: 0) {
                    promptBar
                    stateContent
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(planningContext == nil ? "AI Registry Planner" : "AI Registry Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { closePlanner() }
                        .foregroundColor(.primary)
                }
                if case .results = viewModel.state {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") { viewModel.clear() }
                            .foregroundColor(Color(hex: "e94560"))
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
            if let planningContext {
                VStack(alignment: .leading, spacing: 6) {
                    Text(planningContext.registryName)
                        .font(.headline)
                    Text("Planning for your \(planningContext.event.title.lowercased()) registry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if case .indexing = viewModel.state {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.8)
                    Text("Analysing product catalogue…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(20)
            } else if viewModel.indexReady {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "06d6a0"))
                    Text("Catalogue ready · on-device AI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "06d6a0").opacity(0.12))
                .cornerRadius(20)
            }

            if let intent = viewModel.parsedIntent, intent.hasBudget {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "ffd166"))
                    Text("Budget detected: \(intent.budgetDisplay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "e94560"))
                        .font(.subheadline)

                    TextField(
                        "e.g. cozy kitchen, natural wood, under $400",
                        text: $viewModel.promptText,
                        axis: .vertical
                    )
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($isPromptFocused)
                    .submitLabel(.search)
                    .onSubmit { runSearch() }

                    if !viewModel.promptText.isEmpty {
                        Button {
                            viewModel.promptText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 4, x: 0, y: 2)

                Button(action: runSearch) {
                    Group {
                        if case .searching = viewModel.state {
                            ProgressView().tint(.white).scaleEffect(0.9)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        viewModel.promptText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(.systemGray4)
                            : Color(hex: "e94560")
                    )
                    .foregroundColor(.white)
                    .clipShape(Circle())
                }
                .disabled(viewModel.promptText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.state.isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
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
                onAddItem: { registryRepo.addProduct($0) }
            )
        case .noResults:
            noResultsView
        case .error(let msg):
            errorView(message: msg)
        }
    }

    private var idlePlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Describe Your Perfect Registry")
                .font(.title3)
                .fontWeight(.bold)
            Text("Tell us your style, event, and budget.")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)
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
                .foregroundColor(.secondary)
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
