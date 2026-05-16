//
//  RegistryDetailView.swift
//  WSHackathonApp
//

import SwiftUI

struct RegistryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var cartRepo: CartRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @StateObject private var viewModel = RegistryDetailViewModel()
    @State private var showInviteAlert = false
    @State private var guestName = ""
    @State private var showSuccessToast = false
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()
            
            if let registry = registryRepo.currentRegistry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(registry.displayName.components(separatedBy: " - ").first ?? registry.displayName)
                                .font(.system(size: 36, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                            
                            HStack(spacing: 8) {
                                Text(registry.event.rawValue.uppercased() + " EVENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))
                                
                                Spacer()
                                
                                Button(action: {
                                    showInviteAlert = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.badge.plus")
                                        Text("Invite")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                                    .foregroundColor(.gray)
                                
                                Text(registry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Budget Progress (Mocked)
                        if let budget = registry.budget, !budget.isEmpty {
                            VStack(spacing: 12) {
                                HStack(alignment: .bottom) {
                                    Text("$0") // Mock spent value
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                                    Spacer()
                                    Text("of $\(budget) planned")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(white: 0.9))
                                            .frame(height: 4)
                                        
                                        Capsule()
                                            .fill(Color(red: 0.46, green: 0.50, blue: 0.44))
                                            .frame(width: geometry.size.width * 0.0, height: 4) // Mock progress
                                    }
                                }
                                .frame(height: 4)
                            }
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.9), lineWidth: 1))
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Saved Items
                        if !registry.items.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Saved Items")
                                    .font(.system(size: 24, weight: .regular, design: .serif))
                                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 0) {
                                    ForEach(registry.items) { item in
                                        RegistryItemRow(
                                            viewModel: RegistryItemRowViewModel(
                                                item: item,
                                                registryRepo: registryRepo,
                                                cartRepo: cartRepo,
                                                tabbarVM: tabBarVM
                                            )
                                        )
                                        .padding(.horizontal, 24)
                                        
                                        Divider()
                                            .background(Color(white: 0.9))
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                            .padding(.top, 32)
                        }
                        
                        // Suggested Items
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested For Your Event")
                                .font(.system(size: 24, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                                .padding(.horizontal, 24)
                            
                            Text("Trending items for \(registry.event.rawValue) registries.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(viewModel.suggestedProducts.enumerated()), id: \.element.id) { index, product in
                                        suggestedCard(for: product, index: index)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                            }
                        }
                    }
                }
            else {
                Text("Registry not found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(
            VStack {
                if showSuccessToast {
                    Text("Invite sent to \(guestName)!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 20)
                    Spacer()
                }
            }
        )
        .alert("Invite Guest", isPresented: $showInviteAlert) {
            TextField("Guest Name (e.g. Guest-123)", text: $guestName)
                .textInputAutocapitalization(.never)
            Button("Send") {
                let success = SocketService.shared.sendInvite(toDisplayName: guestName, registry: registryRepo.currentRegistry)
                if success {
                    withAnimation {
                        showSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { 
                            showSuccessToast = false
                            guestName = ""
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) { guestName = "" }
        } message: {
            Text("Enter the exact display name of the guest you want to invite to this registry.")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { /* Add people */ }) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                    }
                    
                    Button(action: { /* Share */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                    }
                }
            }
        }
        .task {
            await viewModel.fetchSuggestedProducts()
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    func suggestedCard(for product: ProductItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 160, height: 160)
                
                if let urlString = product.path, let url = URL(string: AppConstants.API.imageBasePath + urlString) {
                    CustomAsyncImage(url: url)
                        .frame(width: 160, height: 160)
                        .cornerRadius(16)
                }
                
                HStack(alignment: .top) {
                    Text(index % 2 == 0 ? "TRENDING" : "POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: "heart")
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                }
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("BRAND")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(.gray)
                
                Text(product.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                    .lineLimit(2)
                
                if let price = product.price {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.54, green: 0.40, blue: 0.31))
                }
            }
            .frame(width: 160, alignment: .leading)
        }
    }
}

