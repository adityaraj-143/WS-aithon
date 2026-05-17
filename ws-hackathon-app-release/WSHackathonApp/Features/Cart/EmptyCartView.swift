//
//  EmptyCartView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import SwiftUI

struct EmptyCartView: View {

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.brandPrimary.opacity(0.5))
                .padding(.bottom, 4)

            Text(AppStrings.Cart.emptyMessage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Use the tab bar to browse and add items")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .wsCard(cornerRadius: 20, padding: 32)
        .padding(.horizontal, 20)
    }
}
