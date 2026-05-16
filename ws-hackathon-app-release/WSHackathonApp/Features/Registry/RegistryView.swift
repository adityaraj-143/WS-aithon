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

    @StateObject private var socketService = SocketService.shared
    @State private var showCreateSheet = false
    @State private var showPlannerSheet = false
    @State private var showDetail = false
    @State private var pendingPlanningContext: RegistryPlanningContext?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.93)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Registries")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))

                        Text("Your curated planning collections")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    if !socketService.pendingRegistryInvites.isEmpty {
                        invitationsSection
                            .padding(.bottom, 12)
                    }

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
            .navigationDestination(isPresented: $showDetail) {
                RegistryDetailView()
                    .environmentObject(registryRepo)
                    .environmentObject(cartRepo)
            }
            .navigationDestination(isPresented: $showCreateSheet) {
                CreateRegistryView(
                    onCancel: { showCreateSheet = false },
                    onCreateComplete: {
                        showCreateSheet = false
                        showDetail = true
                    },
                    onCreateWithAI: { context in
                        pendingPlanningContext = context
                        showCreateSheet = false
                        showPlannerSheet = true
                    }
                )
                .environmentObject(registryRepo)
                .environmentObject(homeVM)
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
            Task { await homeVM.fetchProducts() }
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
                    showDetail = true
                }
            )
            .environmentObject(registryRepo)
        }
    }
}

private extension RegistryView {
    var invitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Invitations")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(socketService.pendingRegistryInvites, id: \.inviteLink) { invite in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "envelope.fill").font(.system(size: 12)).foregroundColor(.blue))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(invite.fromDisplayName)
                                        .font(.system(size: 14, weight: .bold))
                                    Text("invited you")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text(invite.registryName ?? "A registry")
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    joinRegistry(invite)
                                }) {
                                    Text("Join")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    socketService.acceptInvite(invite)
                                }) {
                                    Text("Ignore")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(16)
                        .frame(width: 220)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
        }
    }

    func joinRegistry(_ invite: ReceiveInvitePayload) {
        // Mock "Joining" logic:
        // In a real app, this would fetch registry data from backend.
        // For the hackathon, we'll create a local copy or just switch to it.
        if let regId = invite.registryId, let uuid = UUID(uuidString: regId) {
            // Check if we already have it
            if !registryRepo.registries.contains(where: { $0.id == uuid }) {
                registryRepo.createRegistry(
                    firstName: invite.fromDisplayName,
                    lastName: " (Shared)",
                    event: .wedding, // Default or parsed from name
                    date: Date(),
                    budget: "Unknown"
                )
                // Update the ID to match the invited one for "sync" illusion
                if var last = registryRepo.registries.last {
                    // This is hacky but for a demo it works to align them
                    // registryRepo.activeRegistryId = last.id
                }
            } else {
                registryRepo.activeRegistryId = uuid
                showDetail = true
            }
        }
        socketService.acceptInvite(invite)
    }

    var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(white: 0.97))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "folder")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("No Registries Yet")
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                
                Text("Create collections for weddings,\ngifting, housewarmings, and more.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create New Registry")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color(red: 0.46, green: 0.50, blue: 0.44))
                .clipShape(Capsule())
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }

    var populatedStateView: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.registries) { registry in
                        Button {
                            registryRepo.activeRegistryId = registry.id
                            showDetail = true
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
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color(red: 0.46, green: 0.50, blue: 0.44))
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
