//
//  RegistryPlanResultView.swift
//  WSHackathonApp
//
//  Shows the curated plan: budget summary card + ranked product rows.
//

import SwiftUI

struct RegistryPlanResultView: View {

    let plan: RegistryPlan
    let onAddAll: () -> Void
    let onAddItem: (ProductItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: Budget Summary Card
                budgetCard

                // MARK: Product List
                VStack(spacing: 12) {
                    ForEach(plan.items) { scored in
                        PlannerProductRow(
                            scored: scored,
                            onAdd: { onAddItem(scored.product) }
                        )
                    }
                }
                .padding(.horizontal, 16)

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
}

// MARK: - Individual product row

private struct PlannerProductRow: View {
    let scored: ScoredProduct
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


