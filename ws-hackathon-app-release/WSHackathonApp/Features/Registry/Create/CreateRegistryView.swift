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
    var onCreateComplete: (() -> Void)? = nil
    var onCreateWithAI: ((RegistryPlanningContext) -> Void)? = nil

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header & Back Button
                HStack {
                    Button {
                        onCancel?() ?? dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // Titles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Registry")
                                .font(.system(size: 34, weight: .regular, design: .serif))
                                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))

                            Text("Plan and organize your perfect collection.")
                                .font(.system(size: 16))
                                .foregroundColor(Color.gray)
                        }
                        .padding(.top, 24)

                        // Form Fields
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("REGISTRY NAME")
                                TextField("e.g., Summer House Renovation", text: $viewModel.registryName)
                                    .formFieldStyle()
                            }

                            VStack(alignment: .leading, spacing: 12) {
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
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("EVENT DATE")
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .formFieldStyle()
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                fieldLabel("BUDGET (OPTIONAL)")
                                HStack {
                                    Text("$")
                                        .foregroundColor(.gray)
                                    TextField("0.00", text: $viewModel.budget)
                                        .keyboardType(.decimalPad)
                                }
                                .formFieldStyle()
                            }
                            
                            // AI Card
                            aiCard
                        }
                        .padding(.bottom, 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Pinned Bottom Button
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    Button {
                        handleCreation()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text(viewModel.isAIEnabled ? "Generate Registry" : "Create Registry")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(viewModel.isValid ? Color(red: 0.46, green: 0.50, blue: 0.44) : Color(white: 0.75))
                        .clipShape(Capsule())
                        .shadow(color: viewModel.isValid ? Color(red: 0.46, green: 0.50, blue: 0.44).opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.isValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(red: 0.96, green: 0.95, blue: 0.93), location: 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationBarHidden(true)
        .task {
            await homeVM.fetchProducts()
        }
    }
    
    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.isAIEnabled.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isAIEnabled ? Color(red: 0.46, green: 0.50, blue: 0.44) : Color.clear)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: viewModel.isAIEnabled ? 0 : 2))
                        
                        if viewModel.isAIEnabled {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generate with AI")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                        
                        Text("Let AI curate the perfect collection")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.4))
                }
                .padding(20)
                .background(viewModel.isAIEnabled ? Color.white : Color.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            if viewModel.isAIEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    TextField(
                        "Describe your registry needs (e.g., cozy brunch for 8, natural materials...)",
                        text: $viewModel.aiPrompt,
                        axis: .vertical
                    )
                    .lineLimit(4...8)
                    .padding(16)
                    .background(Color(white: 0.98))
                    .cornerRadius(12)
                    .padding(20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.9), lineWidth: 1))
    }

    private func handleCreation() {
        if viewModel.isAIEnabled {
            createRegistryAndPlanWithAI()
        } else {
            createRegistryOnly()
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
    
    private func createRegistryOnly() {
        registryRepo.createRegistry(
            firstName: viewModel.effectiveRegistryName,
            lastName: "",
            event: viewModel.selectedEvent,
            date: viewModel.date,
            budget: viewModel.normalizedBudget
        )
        onCreateComplete?()
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
