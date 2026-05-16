//
//  RegistryPlanningContext.swift
//  WSHackathonApp
//

import Foundation

struct RegistryPlanningContext: Hashable {
    let registryName: String
    let event: RegistryEvent
    let date: Date
    let budget: String?
    let aiPrompt: String

    var combinedPrompt: String {
        var parts: [String] = []
        parts.append("Plan a \(event.rawValue.lowercased()) registry")
        parts.append("for \(registryName)")

        if let budget, !budget.isEmpty {
            parts.append("under $\(budget)")
        }

        let trimmedPrompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPrompt.isEmpty {
            parts.append(trimmedPrompt)
        }

        return parts.joined(separator: ", ")
    }
}
