//
//  Registry.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation

enum RegistryEvent: String, CaseIterable, Identifiable, Codable {
    case wedding = "Wedding"
    case baby = "Baby Shower"
    case birthday = "Birthday"
    case housewarming = "Housewarming"
    case holiday = "Holiday"
    case other = "Other"
    
    var id: String { rawValue }
    var title: String { rawValue }
}

struct Registry: Identifiable, Codable {
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

struct RegistryItem: Identifiable, Codable {
    let id: String
    let title: String
    let price: Double
    let imageUrl: String?
    var quantity: Int
}
