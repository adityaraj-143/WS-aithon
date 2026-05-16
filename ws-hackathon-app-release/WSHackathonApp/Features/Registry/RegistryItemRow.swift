//
//  RegistryItemRow.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct RegistryItemRow: View {

    @StateObject private var viewModel: RegistryItemRowViewModel

    init(viewModel: RegistryItemRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                
                if viewModel.imageURL != nil {
                    CustomAsyncImage(url: viewModel.imageURL)
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                }
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text("BRAND")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(.gray)
                
                Text(viewModel.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                    .lineLimit(2)

                Text(viewModel.priceText)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.54, green: 0.40, blue: 0.31)) // Brownish price
            }
            .padding(.top, 4)
            
            Spacer(minLength: 8)
            
            // Actions
            VStack(alignment: .trailing, spacing: 0) {
                Menu {
//                    Button(action: viewModel.addToCart) {
//                        Label("Add to Cart", systemImage: "cart.badge.plus")
//                    }
                    Button(role: .destructive, action: viewModel.removeItem) {
                        Label("Remove Item", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(white: 0.9), lineWidth: 1))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: viewModel.decreaseQty) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    Text(viewModel.quantityText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                        .frame(minWidth: 14, alignment: .center)
                    
                    Button(action: viewModel.increaseQty) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(white: 0.9), lineWidth: 1))
            }
        }
        .frame(height: 80)
        .padding(.vertical, 8)
    }
}
