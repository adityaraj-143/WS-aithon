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

    private var plan: RegistryPlan { response.registryPlan }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                budgetCard

                if !plan.missingEssentials.isEmpty {
                    missingEssentialsCard
                }

                resultSection(
                    title: "Curated Kit",
                    subtitle: "The planner-selected set that covers the event essentials first.",
                    products: plan.items,
                    emptyMessage: "The planner could not build a complete kit for this prompt.",
                    addButtonLabel: "Add curated kit item"
                )

                resultSection(
                    title: "Browseable Matches",
                    subtitle: "Relevant products from semantic search so you can explore beyond the final kit.",
                    products: response.browseProducts,
                    emptyMessage: "No browseable semantic matches were returned.",
                    addButtonLabel: "Add browse result"
                )

                Spacer(minLength: 24)
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        VStack(spacing: 0) {

            // Header gradient band
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Registry Plan")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(plan.items.count) items curated for you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(Color(hex: "e94560"))
                }

                Divider()

                HStack(spacing: 0) {
                    budgetStat(
                        label: "Budget",
                        value: plan.budget == .infinity ? "Unlimited" : String(format: "$%.0f", plan.budget),
                        color: .primary
                    )
                    Divider().frame(height: 40)
                    budgetStat(
                        label: "Total",
                        value: String(format: "$%.2f", plan.totalCost),
                        color: plan.isWithinBudget ? Color(hex: "06d6a0") : .red
                    )
                    Divider().frame(height: 40)
                    budgetStat(
                        label: "Remaining",
                        value: plan.budget == .infinity ? "—" : String(format: "$%.2f", plan.remainingBudget),
                        color: .secondary
                    )
                }

                HStack(spacing: 0) {
                    budgetStat(
                        label: "Coverage",
                        value: "\(Int((plan.coverageScore * 100).rounded()))%",
                        color: plan.coverageScore >= 1 ? Color(hex: "06d6a0") : Color(hex: "ffd166")
                    )
                    Divider().frame(height: 40)
                    budgetStat(
                        label: "Essentials",
                        value: String(format: "$%.2f", plan.budgetBreakdown.essentialsCost),
                        color: .primary
                    )
                    Divider().frame(height: 40)
                    budgetStat(
                        label: "Optional",
                        value: String(format: "$%.2f", plan.budgetBreakdown.optionalCost),
                        color: .secondary
                    )
                }

                detailPills

                if !canAddToRegistry {
                    Text("Create a registry first to add planner results.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: onAddAll) {
                    Label("Add All to Registry", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "e94560"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!canAddToRegistry || plan.items.isEmpty)
                .opacity((!canAddToRegistry || plan.items.isEmpty) ? 0.55 : 1)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray3).opacity(0.4), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func budgetStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var detailPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let eventType = response.intent.eventType {
                    infoPill("Event: \(eventType.capitalized)")
                }

                if response.intent.hasBudget {
                    infoPill("Budget: \(response.intent.budgetDisplay)")
                }

                ForEach(response.intent.styleHints, id: \.self) { style in
                    infoPill(style.capitalized)
                }

                if !response.intent.ownedKeywords.isEmpty {
                    infoPill("Owns: \(response.intent.ownedKeywords.joined(separator: ", "))")
                }

                if !response.intent.excludedKeywords.isEmpty {
                    infoPill("Excludes: \(response.intent.excludedKeywords.joined(separator: ", "))")
                }
            }
        }
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(999)
    }

    private var missingEssentialsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Missing essentials", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundColor(Color(hex: "e94560"))

            Text("These slots could not be covered within the current prompt and budget.")
                .font(.footnote)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                ForEach(plan.missingEssentials, id: \.self) { slot in
                    Text(slot.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "e94560").opacity(0.12))
                        .foregroundColor(Color(hex: "e94560"))
                        .cornerRadius(999)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray3).opacity(0.25), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func resultSection(
        title: String,
        subtitle: String,
        products: [ScoredProduct],
        emptyMessage: String,
        addButtonLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if products.isEmpty {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
            } else {
                VStack(spacing: 12) {
                    ForEach(products) { scored in
                        PlannerProductRow(
                            scored: scored,
                            canAddToRegistry: canAddToRegistry,
                            addButtonLabel: addButtonLabel,
                            onAdd: { onAddItem(scored.product) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Individual product row

private struct PlannerProductRow: View {
    let scored: ScoredProduct
    let canAddToRegistry: Bool
    let addButtonLabel: String
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail
            AsyncImage(url: scored.product.imageURL) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill()
                } else if phase.error != nil {
                    Color(.systemGray5)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                } else {
                    Color(.systemGray5).overlay(ProgressView())
                }
            }
            .frame(width: 72, height: 72)
            .cornerRadius(10)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(scored.product.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let price = scored.product.price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.footnote)
                        .foregroundColor(.primary)
                }

                // Match badge
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption2)
                    Text("\(scored.matchPercent)% match")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(matchColor(for: scored.score).opacity(0.15))
                .foregroundColor(matchColor(for: scored.score))
                .cornerRadius(6)
            }

            Spacer()

            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "e94560"))
            }
            .disabled(!canAddToRegistry)
            .accessibilityLabel(addButtonLabel)
            .opacity(canAddToRegistry ? 1 : 0.45)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color(.systemGray4).opacity(0.35), radius: 4, x: 0, y: 2)
    }

    private func matchColor(for score: Double) -> Color {
        switch score {
        case 0.7...: return Color(hex: "06d6a0")   // high — green
        case 0.5...: return Color(hex: "ffd166")   // medium — amber
        default:     return Color(hex: "e94560")   // low — red-pink
        }
    }
}

