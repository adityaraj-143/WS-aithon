//
//  ProductDetailView.swift
//  WSHackathonApp
//
//  Created by Antigravity on 15/05/26.
//

import SwiftUI

struct ProductDetailView: View {
    @StateObject var viewModel: ProductDetailViewModel
    @EnvironmentObject var cartRepository: CartRepository
    @EnvironmentObject var registryRepository: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @Environment(\.dismiss) var dismiss
    
    private let bgColor = Color(red: 245/255, green: 243/255, blue: 237/255)
    
    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Large Image Header
                    GeometryReader { geo in
                        AsyncImage(url: viewModel.product.imageURL) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color(.systemGray5)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    }
                    .frame(height: 400)
                    
                    // Bottom Sheet Style Detail Info
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Brand & Title & Price
                        VStack(alignment: .leading, spacing: 10) {
                            if let brand = viewModel.product.brand {
                                Text(brand.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                            
                            Text(viewModel.product.title)
                                .font(.system(size: 26, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(viewModel.product.price?.formatted(.currency(code: "USD")) ?? "$0.00")
                                    .font(.system(size: 22, weight: .regular, design: .serif))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                
                                if let retail = viewModel.product.retailPrice, let price = viewModel.product.price, retail > price {
                                    Text(retail.formatted(.currency(code: "USD")))
                                        .font(.system(size: 15, weight: .regular, design: .serif))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                        .strikethrough()
                                }
                            }
                        }
                        .padding(.top, 30)
                        
                        // Pills HStack wrapping
                        HStack(spacing: 10) {
                            if viewModel.product.availability != "NLA" {
                                pill("IN STOCK")
                            }
                            if viewModel.product.isFreeShipping {
                                pill("FREE SHIPPING")
                            }
                            if viewModel.product.canGiftWrap {
                                pill("GIFT WRAP AVAILABLE")
                            }
                        }
                        
                        Divider()
                            .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                            .padding(.vertical, 8)
                        
                        // Specifications Grid
                        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 24) {
                            if let material = viewModel.product.material {
                                specBox(title: "MATERIAL", value: material)
                            }
                            if let type = viewModel.product.productType {
                                specBox(title: "PRODUCT TYPE", value: type)
                            }
                            if let collection = viewModel.product.collection {
                                specBox(title: "COLLECTION", value: collection)
                            }
                            if let color = viewModel.product.color {
                                specBox(title: "COLOR", value: color)
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 24)
                    .background(bgColor)
                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 24))
                    .offset(y: -24) // Overlap the image slightly
                    .padding(.bottom, -24) // Counteract offset for scroll view
                }
            }
            
            // Custom Back Button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.bind(cartRepository: cartRepository, registryRepository: registryRepository)
        }
    }
    
    private var bottomActionBar: some View {
        Button(action: {
            if viewModel.hasActiveRegistry {
                if viewModel.quantityInRegistry > 0 {
                    viewModel.removeFromRegistry()
                } else {
                    viewModel.addToRegistry()
                }
            } else {
                tabBarVM.selectTab(.registry)
            }
        }) {
            HStack {
                Image(systemName: viewModel.quantityInRegistry > 0 ? "minus" : "plus")
                Text(viewModel.hasActiveRegistry ? (viewModel.quantityInRegistry > 0 ? "Remove from Registry" : "Add to Registry") : "Create Registry to Add")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(red: 115/255, green: 125/255, blue: 105/255))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [bgColor.opacity(0), bgColor, bgColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.92, green: 0.91, blue: 0.88))
            .clipShape(Capsule())
    }
    
    private func specBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Shape helper for specific corners
struct CustomCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


