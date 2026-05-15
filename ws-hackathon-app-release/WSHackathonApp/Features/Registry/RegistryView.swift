//
//  RegistryView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

enum RegistryRoute: Hashable {
    case create
    case success
}

struct RegistryView: View {
    @State private var showingDeleteAlert = false

    @StateObject private var viewModel = RegistryViewModel()

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ─── Banner ──────────────────────────────────
                    bannerImage

                    // ─── Content ─────────────────────────────────
                    VStack(spacing: 20) {
                        if viewModel.hasRegistry {
                            registryHeader
                            budgetTrackerCard
                            groupGiftingCard

                            if viewModel.hasItems {
                                registryItemsList
                            } else {
                                emptyItemsView
                            }

                            trendingItemsSection
                        } else {
                            registryCard
                            instructionCard
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.wsBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.Registry.title)
            .navigationBarTitleDisplayMode(.large)

            // MARK: - Navigation
            .navigationDestination(for: RegistryRoute.self) { route in
                switch route {
                case .create:
                    CreateRegistryView()
                case .success:
                    RegistrySuccessView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
        .alert("Delete Registry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteRegistry(using: registryRepo)
            }
        } message: {
            Text("Are you sure you want to delete this registry? This action cannot be undone.")
        }
    }
}

// MARK: - Components

private extension RegistryView {

    // ─── Banner ──────────────────────────────────────────────────
    var bannerImage: some View {
        GeometryReader { geo in
            Image(AppImages.Registry.header)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: 200)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, Color.wsBackground.opacity(0.8)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 200)
    }

    // ─── Create Registry CTA ─────────────────────────────────────
    var registryCard: some View {
        Button {
            tabBarVM.registryPath.append(.create)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Color.wsBrandLight
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.wsBrand)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.Registry.create)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.wsTitle)
                    Text("Start your wish list today")
                        .font(.caption)
                        .foregroundStyle(Color.wsBody)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.wsCaption)
            }
        }
        .buttonStyle(.plain)
        .wsCard()
        .padding(.horizontal, 20)
    }

    // ─── Instructions ────────────────────────────────────────────
    var instructionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppStrings.Registry.topReasons)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.wsCaption)
                .tracking(1)

            ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.wsBrand)
                            .clipShape(Circle())

                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.wsTitle)
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(Color.wsBody)
                        .padding(.leading, 32)
                }

                if index != viewModel.instructions.count - 1 {
                    Divider().padding(.leading, 32)
                }
            }
        }
        .wsCard()
        .padding(.horizontal, 20)
    }

    var emptyItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Color.wsCaption)
            Text(AppStrings.Registry.noItemsAdded)
                .font(.subheadline)
                .foregroundStyle(Color.wsBody)
        }
        .frame(maxWidth: .infinity)
        .wsCard(cornerRadius: 16, padding: 24)
        .padding(.horizontal, 20)
    }

    // ─── Registry Header ─────────────────────────────────────────
    var registryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.displayTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            Text(viewModel.displayDate)
                .font(.subheadline)
                .foregroundStyle(Color.wsBody)

            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Registry", systemImage: "trash")
                    .font(.caption.weight(.medium))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .wsCard()
        .padding(.horizontal, 20)
    }

    // ─── Registry Items ──────────────────────────────────────────
    var registryItemsList: some View {
        VStack(spacing: 12) {
            WSSectionHeader(
                title: "Your Items",
                trailing: "\(viewModel.items.count) items"
            )
            .padding(.horizontal, 20)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    RegistryItemRow(
                        viewModel: RegistryItemRowViewModel(
                            item: item,
                            registryRepo: registryRepo,
                            cartRepo: cartRepo,
                            tabbarVM: tabBarVM
                        )
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // ─── Budget Tracker ──────────────────────────────────────────
    var budgetTrackerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Registry Goal")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.wsTitle)
                Spacer()
                Text("$1,500 / $2,000")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.wsBody)
            }

            ProgressView(value: 0.75)
                .tint(Color.wsBrand)
                .scaleEffect(x: 1, y: 2.5, anchor: .center)
                .clipShape(Capsule())

            Text("75% Funded")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.wsBrand)
        }
        .wsCard()
        .padding(.horizontal, 20)
    }

    // ─── Group Gifting ───────────────────────────────────────────
    var groupGiftingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contributors")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            HStack(spacing: -10) {
                ForEach(0..<5, id: \.self) { _ in
                    Circle()
                        .fill(Color.wsElevated)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(Color.wsCaption)
                        )
                        .overlay(Circle().stroke(Color.wsCard, lineWidth: 2))
                }

                Circle()
                    .fill(Color.wsBrand)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("+3")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(Color.wsCard, lineWidth: 2))
            }
        }
        .wsCard()
        .padding(.horizontal, 20)
    }

    // ─── Trending Items ──────────────────────────────────────────
    var trendingItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            WSSectionHeader(title: "Trending for Weddings")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack {
                                Color.wsElevated
                                Image(systemName: "gift.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.wsBrand.opacity(0.5))
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text("Popular Item \(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.wsTitle)
                                .lineLimit(1)

                            Text("$99.99")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.wsBody)
                        }
                        .frame(width: 120)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
