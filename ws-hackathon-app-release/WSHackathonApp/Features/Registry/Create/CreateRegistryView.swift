//
//  CreateRegistryView.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 04/04/26.
//

import SwiftUI

struct CreateRegistryView: View {

    @StateObject private var viewModel = CreateRegistryViewModel()
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @EnvironmentObject var registryRepo: RegistryRepository

    @State private var navigateToSuccess = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                // ─── Header ──────────────────────────────────
                VStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.wsBrand)
                        .padding(.bottom, 4)

                    Text(AppStrings.Registry.createYourRegistry)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.wsTitle)
                        .multilineTextAlignment(.center)

                    Text("Set up your registry in seconds")
                        .font(.subheadline)
                        .foregroundStyle(Color.wsBody)
                }
                .padding(.top, 24)

                // ─── Form ────────────────────────────────────
                VStack(spacing: 16) {
                    formField(
                        label: AppStrings.Registry.firstName,
                        icon: "person.fill",
                        text: $viewModel.firstName
                    )

                    formField(
                        label: AppStrings.Registry.lastName,
                        icon: "person.fill",
                        text: $viewModel.lastName
                    )

                    // Event picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppStrings.Registry.event)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.wsBody)

                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(Color.wsCaption)
                            Picker(AppStrings.Registry.event, selection: $viewModel.selectedEvent) {
                                ForEach(RegistryEvent.allCases) { event in
                                    Text(event.title).tag(event)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.wsTitle)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.wsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppStrings.Registry.eventDate)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.wsBody)

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.wsCaption)
                            DatePicker(
                                "",
                                selection: $viewModel.date,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .tint(Color.wsBrand)
                        }
                        .padding(12)
                        .background(Color.wsElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .wsCard(cornerRadius: 20, padding: 20)
                .padding(.horizontal, 20)

                // ─── Create Button ───────────────────────────
                Button {
                    registryRepo.createRegistry(
                        firstName: viewModel.firstName,
                        lastName: viewModel.lastName,
                        event: viewModel.selectedEvent,
                        date: viewModel.date
                    )
                    navigateToSuccess = true
                } label: {
                    Text(AppStrings.Registry.createButton)
                }
                .buttonStyle(WSPrimaryButtonStyle(isEnabled: viewModel.isValid))
                .disabled(!viewModel.isValid)
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .background(Color.wsBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuccess) {
            RegistrySuccessView()
        }
    }

    // ─── Reusable Form Field ─────────────────────────────────────
    private func formField(label: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.wsBody)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Color.wsCaption)
                TextField(label, text: text)
                    .font(.body)
                    .foregroundStyle(Color.wsTitle)
            }
            .padding(12)
            .background(Color.wsElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    CreateRegistryView()
}
