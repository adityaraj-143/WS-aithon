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
    
    private let accentColor = Color.brandPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // MARK: - Image Section
            ZStack(alignment: .top) {
                CustomAsyncImage(url: product.imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
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
                                    .foregroundColor(accentColor)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            
                            Text("\(quantity)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .frame(minWidth: 12)
                            
                            Button(action: onAdd) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(accentColor)
                                    .frame(width: 24, height: 24)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(4)
                        .background(Color.surfacePrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    } else {
                        Button(action: onAdd) {
                            ZStack {
                                Circle()
                                    .fill(Color.surfacePrimary)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.borderSubtle, lineWidth: 1))
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "cart")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                }
                .padding(12)
            }
            
            // MARK: - Text Section
            VStack(alignment: .leading, spacing: 6) {
                if let brand = product.brand {
                    Text(brand.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .kerning(0.5)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
                
                Text(product.title)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .kerning(0.3)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 44, alignment: .topLeading)
                
                if let price = product.price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
    
    @ViewBuilder
    private var statusPill: some View {
        let status = getStatus()
        Text(status)
            .font(.system(size: 10, weight: .bold))
            .kerning(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.surfacePrimary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
