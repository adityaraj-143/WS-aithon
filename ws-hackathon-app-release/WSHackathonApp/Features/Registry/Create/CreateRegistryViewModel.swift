//
//  CreateRegistryViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
import Combine

@MainActor
final class CreateRegistryViewModel: ObservableObject {
    @Published var registryName: String = ""
    @Published var selectedEvent: RegistryEvent = .wedding
    @Published var date: Date = Date()
    @Published var budget: String = ""
    
    var isValid: Bool {
        !registryName.isEmpty
    }
}
