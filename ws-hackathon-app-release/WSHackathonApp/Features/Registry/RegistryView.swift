//
//  RegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryView: View {

    @StateObject private var viewModel = RegistryViewModel()

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var homeVM: HomeViewModel

    @State private var showCreateSheet = false
    @State private var showPlannerSheet = false
    @State private var showDetailSheet = false
    @State private var pendingPlanningContext: RegistryPlanningContext?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.93)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Registries")
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))

                        Text("Your curated planning collections")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    Group {
                        if viewModel.hasRegistry {
                            populatedStateView
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
            Task { await homeVM.fetchProducts() }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateRegistryView(
                onCancel: { showCreateSheet = false },
                onCreateWithAI: { context in
                    pendingPlanningContext = context
                    showCreateSheet = false
                    showPlannerSheet = true
                }
            )
            .environmentObject(registryRepo)
            .environmentObject(homeVM)
        }
        .sheet(isPresented: $showPlannerSheet, onDismiss: {
            pendingPlanningContext = nil
        }) {
            RegistryPlannerView(
                productDTOs: homeVM.productDTOs,
                planningContext: pendingPlanningContext,
                onClose: { showPlannerSheet = false },
                onAddAllComplete: {
                    showPlannerSheet = false
                    showDetailSheet = true
                }
            )
            .environmentObject(registryRepo)
        }
        .sheet(isPresented: $showDetailSheet) {
            RegistryDetailView()
                .environmentObject(registryRepo)
                .environmentObject(cartRepo)
        }
    }
}

private extension RegistryView {
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("No Registries Yet")
                .font(.system(size: 28, weight: .regular, design: .serif))

            Button("Create Registry with AI") {
                showCreateSheet = true
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    var populatedStateView: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.registries) { registry in
                        Button {
                            registryRepo.activeRegistryId = registry.id
                            showDetailSheet = true
                        } label: {
                            registryCard(
                                title: registry.displayName,
                                type: registry.event.rawValue.uppercased() + " EVENT",
                                date: registry.date.formatted(date: .abbreviated, time: .omitted),
                                itemsCount: "\(registry.items.count) Items",
                                budget: registry.budget
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }

            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color(red: 0.91, green: 0.27, blue: 0.38))
                    .clipShape(Circle())
            }
            .padding()
        }
    }

    func registryCard(title: String, type: String, date: String, itemsCount: String, budget: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))

                    Text(type)
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))

                    if let budget = budget, !budget.isEmpty {
                        Text("Budget: $\(budget)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.gray)
                    .padding(.top, 4)
            }
            .padding(24)

            Divider()
                .padding(.horizontal, 24)

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.gray)
                    Text(date)
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray)
                }

                Spacer()

                Text(itemsCount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}
