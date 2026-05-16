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
    @Environment(\.dismiss) var dismiss
    
    @State private var showSuccessAlert = false
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
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
                        // Titles
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
                        
                        // Form Fields
                        VStack(alignment: .leading, spacing: 24) {
                            // Registry Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("REGISTRY NAME")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color.gray)
                                
                                TextField("e.g., Summer House Renovation", text: $viewModel.registryName)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(white: 0.9), lineWidth: 1)
                                    )
                            }
                            
                            // Event Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EVENT TYPE")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color.gray)
                                
                                Menu {
                                    Picker("Event Type", selection: $viewModel.selectedEvent) {
                                        ForEach(RegistryEvent.allCases) { event in
                                            Text(event.title).tag(event)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedEvent.title)
                                            .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.18))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
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
                            
                            // Event Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EVENT DATE")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color.gray)
                                
                                HStack {
                                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                        .labelsHidden()
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(white: 0.9), lineWidth: 1)
                                )
                            }
                            
                            // Budget (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BUDGET (OPTIONAL)")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.0)
                                    .foregroundColor(Color.gray)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.gray)
                                    TextField("0.00", text: $viewModel.budget)
                                        .keyboardType(.decimalPad)
                                }
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
                    }
                    .padding(.horizontal, 24)
                }
                
                // Bottom Bar
                VStack(spacing: 0) {
                    Divider()
                        .background(Color(white: 0.9))
                    
                    Button(action: {
                        registryRepo.createRegistry(
                            firstName: viewModel.registryName,
                            lastName: "",
                            event: viewModel.selectedEvent,
                            date: viewModel.date,
                            budget: viewModel.budget.isEmpty ? nil : viewModel.budget
                        )
                        showSuccessAlert = true
                    }) {
                        Text("Create Registry")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isValid ? Color(red: 0.46, green: 0.50, blue: 0.44) : Color.gray.opacity(0.5)) // Olive green when valid
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
        .alert("Registry Created", isPresented: $showSuccessAlert) {
            Button("Browse Items") {
                tabBarVM.resetRegistryFlow()
            }
        } message: {
            Text("Your registry '\(viewModel.registryName)' has been successfully created.")
        }
    }
}

#Preview {
    CreateRegistryView()
}
