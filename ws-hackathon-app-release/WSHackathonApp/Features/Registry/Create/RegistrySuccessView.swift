//
//  RegistrySuccessView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI

struct RegistrySuccessView: View {

    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var tabBarVM: WSTabBarViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.wsBrandLight)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.wsBrand)
            }

            Text("Registry Created 🎉")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.wsTitle)

            Text(registryRepo.currentRegistry?.displayName ?? "")
                .font(.headline)
                .foregroundStyle(Color.wsBody)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                tabBarVM.resetRegistryFlow()
            } label: {
                Text("Back to Registry")
            }
            .buttonStyle(WSPrimaryButtonStyle())
            .padding(.horizontal, 40)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.wsBackground.ignoresSafeArea())
    }
}
