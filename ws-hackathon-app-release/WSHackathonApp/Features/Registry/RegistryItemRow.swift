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
                
                HStack(spacing: 6) {
                    Button(action: viewModel.toggleUpvote) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isUpvoted ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.isUpvoted ? .red : .gray)
                            
                            if viewModel.upvoteCount > 0 {
                                Text("\(viewModel.upvoteCount)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if !viewModel.upvotedByText.isEmpty {
                        Text(viewModel.upvotedByText)
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.8))
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
                            .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))
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
                } else {
                    Spacer()
                    Button(action: viewModel.removeFromCart) {
                        HStack(spacing: 4) {
                            Image(systemName: "cart.badge.minus")
                            Text("Remove")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.44))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .overlay(Capsule().stroke(Color(red: 0.46, green: 0.50, blue: 0.44).opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
        .frame(height: 80)
        .padding(.vertical, 8)
    }
}
