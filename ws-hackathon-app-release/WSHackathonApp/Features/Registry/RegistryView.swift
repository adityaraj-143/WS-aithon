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
    case detail
}

struct RegistryView: View {
    
    @StateObject private var viewModel = RegistryViewModel()
    
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    
    var body: some View {
        NavigationStack(path: $tabBarVM.registryPath) {
            
            ZStack {
                Color(red: 0.96, green: 0.95, blue: 0.93)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Header
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
                    
                    if viewModel.hasRegistry {
                        populatedStateView
                    } else {
                        emptyStateView
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: RegistryRoute.self) { route in
                switch route {
                case .create:
                    CreateRegistryView()
                    
                case .success:
                    RegistrySuccessView()
                    
                case .detail:
                    RegistryDetailView()
                }
            }
        }
        .onAppear {
            viewModel.bind(repository: registryRepo)
        }
    }
}

// MARK: - Components
private extension RegistryView {
    
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "folder.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundColor(Color(white: 0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(white: 0.8), lineWidth: 2)
                            .frame(width: 24, height: 16)
                            .offset(y: 4)
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Registries Yet")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                
                Text("Create collections for weddings,\ngifting, housewarmings, and more.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                tabBarVM.registryPath.append(.create)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                    Text("Create New Registry")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(Color(red: 0.46, green: 0.50, blue: 0.44)) // Olive green
                .clipShape(Capsule())
            }
            .padding(.top, 16)
            
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
                        Button(action: {
                            registryRepo.activeRegistryId = registry.id
                            tabBarVM.registryPath.append(.detail)
                        }) {
                            registryCard(
                                title: registry.displayName,
                                type: registry.event.rawValue.uppercased() + " EVENT",
                                date: registry.date.formatted(date: .abbreviated, time: .omitted),
                                itemsCount: "\(registry.items.count) Items",
                                budget: registry.budget
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            
            // Floating Action Button
            Button {
                tabBarVM.registryPath.append(.create)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color(red: 0.46, green: 0.50, blue: 0.44))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(24)
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
                        .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44)) // Olive green text
                    
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
