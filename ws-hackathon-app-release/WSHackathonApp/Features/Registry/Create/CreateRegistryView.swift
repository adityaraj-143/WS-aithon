//
//  CreateRegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct CreateRegistryView: View {

    @StateObject private var viewModel = CreateRegistryViewModel()
    @EnvironmentObject var registryRepo: RegistryRepository
    @EnvironmentObject var homeVM: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var onCancel: (() -> Void)? = nil
    var onCreateWithAI: ((RegistryPlanningContext) -> Void)? = nil

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        onCancel?() ?? dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Registry")
                                .font(.system(size: 36, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))

                            Text("Plan and organize your perfect collection.")
                                .font(.system(size: 16))
                                .foregroundColor(Color.gray)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)

                        VStack(alignment: .leading, spacing: 24) {
                            fieldLabel("REGISTRY NAME")
                            TextField("e.g., Summer House Renovation", text: $viewModel.registryName)
                                .formFieldStyle()

                            fieldLabel("EVENT TYPE")
                            Menu {
                                Picker("Event Type", selection: $viewModel.selectedEvent) {
                                    ForEach(RegistryEvent.allCases) { event in
                                        Text(event.title).tag(event)
                                    }
                                }
                            } label: {
                                menuLabel(viewModel.selectedEvent.title)
                            }

                            fieldLabel("EVENT DATE")
                            DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                .labelsHidden()
                                .formFieldStyle()

                            fieldLabel("BUDGET (OPTIONAL)")
                            HStack {
                                Text("$")
                                    .foregroundColor(.gray)
                                TextField("0.00", text: $viewModel.budget)
                                    .keyboardType(.decimalPad)
                            }
                            .formFieldStyle()

                            fieldLabel("AI REGISTRY BRIEF")
                            TextField(
                                "e.g., cozy brunch for 8, natural materials, I already have cookware, no barware",
                                text: $viewModel.aiPrompt,
                                axis: .vertical
                            )
                            .lineLimit(4...8)
                            .formFieldStyle()
                        }
                    }
                    .padding(.horizontal, 24)
                }

                VStack(spacing: 0) {
                    Divider().background(Color(white: 0.9))

                    Button {
                        createRegistryAndPlanWithAI()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("Create Registry")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isValid ? Color(hex: "e94560") : Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .disabled(!viewModel.isValid)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(Color(red: 0.96, green: 0.95, blue: 0.93))
            }
        }
        .navigationBarHidden(true)
        .task {
            await homeVM.fetchProducts()
        }
    }

    private func createRegistryAndPlanWithAI() {
        let context = viewModel.planningContext
        registryRepo.createRegistry(
            firstName: context.registryName,
            lastName: "",
            event: context.event,
            date: context.date,
            budget: context.budget
        )
        onCreateWithAI?(context)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.0)
            .foregroundColor(Color.gray)
    }

    private func menuLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.gray)
        }
        .formFieldStyle()
    }
}

private extension View {
    func formFieldStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.9), lineWidth: 1)
            )
    }
}

#Preview {
    CreateRegistryView()
}
