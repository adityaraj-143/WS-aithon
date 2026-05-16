//
//  RegistryPlanResultView.swift
//  WSHackathonApp
//
//  Shows the curated plan: budget summary card + ranked product rows.
//

import SwiftUI

struct RegistryPlanResultView: View {

    let response: PlannedRegistryResponse
    let canAddToRegistry: Bool
    let onAddAll: () -> Void
    let onAddItem: (ProductItem) -> Void
    let planningContext: RegistryPlanningContext?

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @State private var showSelectedItems = false
    
    private var plan: RegistryPlan { response.registryPlan }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    heroSection

                    statsGrid

                    if !plan.missingEssentials.isEmpty {
                        missingEssentialsSection
                    }

                    resultSection(
                        title: "Curated Collection",
                        products: plan.items,
                        emptyMessage: "The planner could not build a complete kit for this prompt."
                    )

                    resultSection(
                        title: "Explore More",
                        products: response.browseProducts,
                        emptyMessage: "No browseable semantic matches were returned."
                    )

                    Spacer(minLength: 120) // Extra space for the floating bar
                }
                .padding(.top, 24)
            }
            
            bottomActionBar
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(planningContext?.registryName ?? "Registry")
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundColor(.textPrimary)

            Text("Planning your \(planningContext?.event.title.lowercased() ?? "event") registry for intimate gatherings and timeless rituals.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            HStack(spacing: 8) {
                let eventType = planningContext?.event.title.uppercased() ?? ""
                let hints = response.intent.styleHints.map { $0.uppercased() }
                let allHints = ([eventType] + hints).filter { !$0.isEmpty }
                
                Text(allHints.joined(separator: "  ·  "))
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.0)
                    .foregroundColor(.brandPrimary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 24) {
            HStack(spacing: 0) {
                statItem(label: "BUDGET", value: plan.budget == .infinity ? "—" : String(format: "$%.0f", plan.budget))
                statItem(label: "TOTAL", value: String(format: "$%.0f", plan.totalCost))
                statItem(label: "REMAINING", value: plan.budget == .infinity ? "—" : String(format: "$%.0f", plan.remainingBudget))
            }
            HStack(spacing: 0) {
                statItem(label: "COVERAGE", value: "\(Int((plan.coverageScore * 100).rounded()))%")
                statItem(label: "ESSENTIALS", value: String(format: "%.0f", plan.budgetBreakdown.essentialsCost / 50))
                statItem(label: "OPTIONAL", value: String(format: "%.0f", plan.budgetBreakdown.optionalCost / 50))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(24)
        .padding(.horizontal, 24)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .kerning(1)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Missing Essentials

    private var missingEssentialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "triangle")
                    .font(.system(size: 10, weight: .bold))
                Text("MISSING ESSENTIALS (\(plan.missingEssentials.count))")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1)
            }
            .foregroundColor(.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.missingEssentials, id: \.self) { slot in
                        Text(slot.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5).opacity(0.3))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Results Section

    private func resultSection(
        title: String,
        products: [ScoredProduct],
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .padding(.horizontal, 24)

            if products.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 24) {
                    ForEach(products) { scored in
                        PlannerProductCard(
                            scored: scored,
                            isSelected: isProductInRegistry(scored.product),
                            showTickByDefault: title.contains("Curated"),
                            onAdd: { onAddItem(scored.product) }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func isProductInRegistry(_ product: ProductItem) -> Bool {
        return registryRepo.currentRegistry?.items.contains(where: { $0.id == product.id }) ?? false
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack {
            let curatedCount = plan.items.count
            let browseSelectedCount = response.browseProducts.filter { isProductInRegistry($0.product) }.count
            let totalSelected = curatedCount + browseSelectedCount
            
            Button {
                showSelectedItems = true
            } label: {
                HStack(spacing: 4) {
                    Text("\(totalSelected) Items Selected")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            Button(action: onAddAll) {
                Text("Add to Registry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .sheet(isPresented: $showSelectedItems) {
            SelectedItemsSheet(
                plan: plan,
                browseProducts: response.browseProducts,
                isProductInRegistry: isProductInRegistry
            )
        }
    }
}

// MARK: - Product Card

private struct PlannerProductCard: View {
    let scored: ScoredProduct
    let isSelected: Bool
    let showTickByDefault: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomTrailing) {
                    // Image
                    CustomAsyncImage(url: scored.product.imageURL)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Selection button
                    Button(action: onAdd) {
                        ZStack {
                            Circle()
                                .fill((isSelected || showTickByDefault) ? Color.brandPrimary : Color.surfacePrimary)
                                .frame(width: 36, height: 36)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            if isSelected || showTickByDefault {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                    }
                    .padding(12)
                }
                
                // Match badge
                Text("\(scored.matchPercent)% MATCH")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(0.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text((scored.product.brand ?? "ESSENTIALS").uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .kerning(1)
                    .foregroundColor(.textSecondary)
                
                Text(scored.product.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.textPrimary)

                if let price = scored.product.price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Selected Items Sheet

struct SelectedItemsSheet: View {
    @Environment(\.dismiss) var dismiss
    let plan: RegistryPlan
    let browseProducts: [ScoredProduct]
    let isProductInRegistry: (ProductItem) -> Bool
    
    var selectedBrowseProducts: [ScoredProduct] {
        browseProducts.filter { isProductInRegistry($0.product) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Selected Items")
                            .font(.system(size: 32, weight: .regular, design: .serif))
                            .padding(.top, 24)
                        
                        VStack(spacing: 0) {
                            // Curated Items
                            ForEach(plan.items) { scored in
                                SimpleProductRow(scored: scored)
                                Divider().padding(.vertical, 8)
                            }
                            
                            // Selected Browse Products
                            ForEach(selectedBrowseProducts) { scored in
                                SimpleProductRow(scored: scored)
                                Divider().padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

struct SimpleProductRow: View {
    let scored: ScoredProduct
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Image
            CustomAsyncImage(url: scored.product.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text((scored.product.brand ?? "ESSENTIALS").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1)
                    .foregroundColor(.textSecondary)
                
                Text(scored.product.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let price = scored.product.price {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.system(size: 14))
                        .foregroundColor(.brandPrimary)
                }
            }
            
            Spacer()
            
            // Match badge
            Text("\(scored.matchPercent)%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

