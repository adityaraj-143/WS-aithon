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
    
    private var totalSpent: Double {
        guard let registry = registryRepo.currentRegistry else { return 0 }
        return registry.items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    private var budgetAmount: Double {
        guard let registry = registryRepo.currentRegistry,
              let budgetStr = registry.budget,
              let amount = Double(budgetStr.filter { "0123456789.".contains($0) }) else { return 0 }
        return amount
    }
    
    private var percentLeft: Int {
        let budget = budgetAmount
        guard budget > 0 else { return 100 }
        let spent = totalSpent
        let used = (spent / budget) * 100
        return max(0, 100 - Int(used))
    }
    
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
                                Text("\(registry.event.rawValue) EVENT • \(registry.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))
                                    .textCase(.uppercase)
                                
                                Spacer()
                            }
                                
                                if !registry.collaboratorNames.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.2")
                                            .font(.system(size: 12))
                                        Text("With: " + registry.collaboratorNames.joined(separator: ", "))
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Budget Progress
                        if let budget = registry.budget, !budget.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("$\(Int(totalSpent))")
                                            .font(.system(size: 44, weight: .regular, design: .serif))
                                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                                        Text("amount used so far")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(white: 0.9))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(Color(red: 0.46, green: 0.50, blue: 0.44))
                                            .frame(width: geometry.size.width * min(1.0, (budgetAmount > 0 ? (totalSpent / budgetAmount) : 0)), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                HStack {
                                    Text("Budget: $\(budget)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text("\(percentLeft)% LEFT")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
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
                        .padding(.top, 64)
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
                    Button(action: { showInviteAlert = true }) {
                        Image(systemName: "person.badge.plus")
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

