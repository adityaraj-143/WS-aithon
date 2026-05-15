//
//  ProductCardView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
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
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
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
                    statusPill
                    Spacer()
                    Button(action: onAddToRegistry) {
                        Image(systemName: registryQuantity > 0 ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(registryQuantity > 0 ? .red : .black)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
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
        // ✅ FIX: Card background + rounded corners so it looks self-contained
        .background(Color(red: 245/255, green: 243/255, blue: 237/255))
        .cornerRadius(16)
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
