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
                    .foregroundColor(.textSecondary)
                
                Text(viewModel.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text(viewModel.priceText)
                    .font(.system(size: 14))
                    .foregroundColor(.brandPrimary) // Brownish price
                
                HStack(spacing: 6) {
                    Button(action: viewModel.toggleUpvote) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isUpvoted ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.isUpvoted ? Color.red : Color.gray)
                            
                            if viewModel.upvoteCount > 0 {
                                Text("\(viewModel.upvoteCount)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    if !viewModel.upvotedByText.isEmpty {
                        Text(viewModel.upvotedByText)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary.opacity(0.8))
                            .italic()
                            .lineLimit(1)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.top, 4)
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 0) {
                if !viewModel.isInCart {
                    Button(action: viewModel.addToCart) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.brandPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: viewModel.decreaseQty) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text(viewModel.quantityText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .frame(minWidth: 14, alignment: .center)
                        
                        Button(action: viewModel.increaseQty) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.borderSubtle, lineWidth: 1))
                } else {
                    Spacer()
                    Button(action: viewModel.removeFromCart) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.badge.minus")
                            Text("Remove")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
        .frame(height: 80)
        .padding(.vertical, 8)
    }
}
