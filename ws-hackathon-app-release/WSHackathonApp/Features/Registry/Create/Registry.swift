//
//  Registry.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation
struct Registry: Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let event: RegistryEvent
    let date: Date
    let budget: String?
    var items: [RegistryItem]
    
    var displayName: String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName) - \(event.title)"
    }
}
