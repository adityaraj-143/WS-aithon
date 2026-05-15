//
//  RegistryPlannerView.swift
//  WSHackathonApp
//
//  Main entry point for the AI registry planner feature.
//  Shown as a sheet from RegistryView when the user taps "Plan My Registry".
//

import SwiftUI

struct RegistryPlannerView: View {

    // MARK: - Environment

    @EnvironmentObject var registryRepo: RegistryRepository

    // MARK: - State

    @StateObject private var viewModel = RegistryPlannerViewModel()

    /// The raw DTOs needed to build the embedding index.
    /// Passed in from HomeViewModel / the fetch that already happened.
    let productDTOs: [ProductItemDTO]

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPromptFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()

                VStack(spacing: 0) {
                    promptBar
                    stateContent
                }
            }
            .navigationTitle("AI Registry Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
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
            viewModel.buildIndex(dtos: productDTOs)
        }
    }

    // MARK: - Prompt Input Bar

    private var promptBar: some View {
        VStack(spacing: 12) {

            // Indexing status badge
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

            // Budget hint (live parsing)
            if let intent = viewModel.parsedIntent, intent.hasBudget {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "ffd166"))
                    Text("Budget detected: \(intent.budgetDisplay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Text input + Search button
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
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.9)
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
                    .shadow(color: Color(hex: "e94560").opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .disabled(viewModel.promptText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.state.isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .animation(.spring(response: 0.3), value: viewModel.parsedIntent?.hasBudget)
    }

    // MARK: - State-based Content

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.state {
        case .idle:
            idlePlaceholder

        case .indexing:
            loadingView(message: "Building on-device AI index…")

        case .searching:
            loadingView(message: "Finding your perfect products…")

        case .results(let plan):
            RegistryPlanResultView(
                plan: plan,
                onAddAll: { addAllToRegistry(plan: plan) },
                onAddItem: { registryRepo.addProduct($0) }
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        case .noResults:
            noResultsView

        case .error(let msg):
            errorView(message: msg)
        }
    }

    // MARK: - Placeholder Views

    private var idlePlaceholder: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "e94560"), Color(hex: "ffd166")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Describe Your Perfect Registry")
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Tell us your style, event, and budget.\nWe'll find the best products — entirely on your device.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Suggestion chips
            VStack(spacing: 10) {
                suggestionChip("🍳 Modern kitchen setup under $500")
                suggestionChip("🌿 Natural wood & ceramic cookware")
                suggestionChip("🥂 Elegant barware, budget $300")
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            viewModel.promptText = text
            isPromptFocused = false
            runSearch()
        } label: {
            Text(text)
                .font(.footnote)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .foregroundColor(.primary)
                .cornerRadius(20)
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }

    private func loadingView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No products matched your prompt.")
                .font(.headline)
            Text("Try different keywords or relax the budget constraint.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Actions

    private func runSearch() {
        isPromptFocused = false
        viewModel.search()
    }

    private func addAllToRegistry(plan: RegistryPlan) {
        for scored in plan.items {
            registryRepo.addProduct(scored.product)
        }
        dismiss()
    }
}
