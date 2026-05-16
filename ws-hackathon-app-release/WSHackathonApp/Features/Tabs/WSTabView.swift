//
//  WSTabView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct WSTabView: View {    
    @EnvironmentObject var viewModel: WSTabBarViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var homeVM: HomeViewModel
    
    @StateObject private var socketService = SocketService.shared
    @State private var showingGlobalInvite = false
    @State private var pendingInvite: ReceiveInvitePayload?
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            ForEach(viewModel.tabs, id: \.rawValue) { tab in
                view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .alert("New Invitation", isPresented: $showingGlobalInvite) {
            Button("Join Registry") {
                if let invite = pendingInvite {
                    joinRegistry(invite)
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            if let invite = pendingInvite {
                Text("\(invite.fromDisplayName) invited you to join '\(invite.registryName ?? "their registry")'.")
            }
        }
        .onChange(of: socketService.lastReceivedInvite) { newInvite in
            if let invite = newInvite {
                pendingInvite = invite
                showingGlobalInvite = true
            }
        }
    }
    
    private func joinRegistry(_ invite: ReceiveInvitePayload) {
        if let regId = invite.registryId, let uuid = UUID(uuidString: regId) {
            // Switch to registry tab
            viewModel.selectedTab = .registry
            
            // Handle joining
            if !registryRepository.registries.contains(where: { $0.id == uuid }) {
                registryRepository.createRegistry(
                    firstName: invite.fromDisplayName,
                    lastName: " (Shared)",
                    event: .wedding,
                    date: Date(),
                    budget: nil
                )
            } else {
                registryRepository.activeRegistryId = uuid
            }
            
            // Join real-time room for updates
            SocketService.shared.joinRoom(registryId: uuid.uuidString)
        }
        socketService.acceptInvite(invite)
    }
    
    @ViewBuilder
    private func view(for tab: TabItem) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .registry:
            RegistryView()
        }
    }
}


#Preview {
    WSTabView()
}
