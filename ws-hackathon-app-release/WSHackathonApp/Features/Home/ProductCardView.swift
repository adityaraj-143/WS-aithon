//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import SwiftUI

struct ProductCardView: View {
    let product: ProductItem
    let quantity: Int
    let registryQuantity: Int
    let onAdd: () -> Void
    let onRemove: () -> Void
    let onAddToRegistry: () -> Void
    let onRemoveFromRegistry: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        // ✅ FIX: VStack aligned to .top so it never floats or grows unexpectedly
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Image Section
            ZStack(alignment: .top) {
                AsyncImage(url: product.imageURL) { phase in
                    switch phase {
                    case .empty:
                        Color(red: 0.95, green: 0.95, blue: 0.95)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        Color(red: 0.95, green: 0.95, blue: 0.95)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    @unknown default:
                        Color(red: 0.95, green: 0.95, blue: 0.95)
                    }
                }
                .frame(maxWidth: .infinity)
                // ✅ FIX: Reduced from 200 to 160 so text section has breathing room
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .clipped()
                .onTapGesture(perform: onSelect)
                
                HStack(alignment: .top) {
                    if quantity == 0 {
                        statusPill
                    }
                    
                    Spacer()
                    
                    if quantity > 0 {
                        HStack(spacing: 8) {
                            Button(action: onRemove) {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            
                            Text("\(quantity)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .frame(minWidth: 12)
                            
                            Button(action: onAdd) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(2)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        Button(action: onAdd) {
                            Image(systemName: "cart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                        }
                    }
                }
                .padding(10)
            }
            
            // MARK: - Text Section
            // ✅ FIX: Wrap in a fixed-min-height container so short titles
            //         don't cause the card to report less height than its neighbour
            VStack(alignment: .leading, spacing: 4) {
                if let brand = product.brand {
                    Text(brand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .lineLimit(1)
                }
                
                Text(product.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 40, alignment: .topLeading)
                
                Text(product.price?.formatted(.currency(code: "USD")) ?? "$0.00")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.35, blue: 0.3))
            }
            .padding(.top, 10)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var statusPill: some View {
        let status = getStatus()
        Text(status)
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
    }
    
    private func getStatus() -> String {
        if let retail = product.retailPrice, let price = product.price, retail > price {
            return "SALE"
        } else if product.availability == "BACK_ORDERED" {
            return "FEW LEFT"
        } else {
            return "IN STOCK"
        }
    }
}
