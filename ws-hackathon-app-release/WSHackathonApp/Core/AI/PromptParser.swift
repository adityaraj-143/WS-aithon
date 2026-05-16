//
//  PromptParser.swift
//  WSHackathonApp
//
//  Extracts structured intent from a free-text user prompt.
//  The semantic matching is handled by NLEmbedding — this parser
    //  extracts budget plus lightweight planner hints like event, style,
    //  owned items, and exclusions.
//

import Foundation

struct RegistryPromptIntent {
    /// The free-text prompt as entered by the user.
    let rawPrompt: String

    /// Parsed budget ceiling, e.g. 500.0 from "under $500" or "budget of 300".
    /// `nil` means no budget constraint was detected.
    let budget: Double?
    let eventType: String?
    let styleHints: [String]
    let ownedKeywords: [String]
    let excludedKeywords: [String]

    /// Whether a budget was explicitly mentioned in the prompt.
    var hasBudget: Bool { budget != nil }

    /// Formatted budget string for display.
    var budgetDisplay: String {
        guard let budget else { return "No budget set" }
        return String(format: "$%.0f", budget)
    }
}

struct PromptParser {

    // MARK: - Patterns to detect budget phrases

    /// Regex patterns in priority order. Each captures a number.
    private static let budgetPatterns: [String] = [
        // "under $500", "under 500"
        #"under\s*\$?(\d+(?:\.\d{1,2})?)"#,
        // "budget of $300", "budget: 300"
        #"budget\s*(?:of\s*|:\s*)?\$?(\d+(?:\.\d{1,2})?)"#,
        // "up to $200"
        #"up\s+to\s*\$?(\d+(?:\.\d{1,2})?)"#,
        // "within $400", "within 400"
        #"within\s*\$?(\d+(?:\.\d{1,2})?)"#,
        // "spend $250", "spending $250"
        #"spend(?:ing)?\s*\$?(\d+(?:\.\d{1,2})?)"#,
        // "max $600", "maximum $600"
        #"max(?:imum)?\s*\$?(\d+(?:\.\d{1,2})?)"#,
        // Bare dollar amount: "$500" (last resort, least specific)
        #"\$(\d+(?:\.\d{1,2})?)"#,
    ]

    private static let knownEvents: [String] = [
        "birthday", "wedding", "housewarming", "anniversary", "baby shower", "dinner", "brunch"
    ]

    private static let knownStyles: [String] = [
        "elegant", "minimal", "cozy", "modern", "rustic", "classic", "luxury", "warm", "neutral",
        "natural", "practical", "premium", "organic"
    ]

    private static let ownershipPatterns: [String] = [
        #"i\s+already\s+have\s+([a-z0-9\s\-]+)"#,
        #"already\s+have\s+([a-z0-9\s\-]+)"#,
        #"i\s+have\s+([a-z0-9\s\-]+)"#
    ]

    private static let exclusionPatterns: [String] = [
        #"remove\s+([a-z0-9\s\-]+)"#,
        #"no\s+([a-z0-9\s\-]+)"#,
        #"without\s+([a-z0-9\s\-]+)"#,
        #"exclude\s+([a-z0-9\s\-]+)"#
    ]

    // MARK: - Parse

    func parse(_ prompt: String) -> RegistryPromptIntent {
        let budget = extractBudget(from: prompt)
        return RegistryPromptIntent(
            rawPrompt: prompt,
            budget: budget,
            eventType: extractEventType(from: prompt),
            styleHints: extractKnownTerms(from: prompt, terms: Self.knownStyles),
            ownedKeywords: extractPatternCaptures(from: prompt, patterns: Self.ownershipPatterns),
            excludedKeywords: extractPatternCaptures(from: prompt, patterns: Self.exclusionPatterns)
        )
    }

    // MARK: - Private

    private func extractBudget(from text: String) -> Double? {
        for pattern in Self.budgetPatterns {
            if let match = firstCapture(in: text, pattern: pattern) {
                return Double(match)
            }
        }
        return nil
    }

    /// Returns the first capture group from the first regex match.
    private func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return nil }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1 else { return nil }

        let captureRange = match.range(at: 1)
        guard let swiftRange = Range(captureRange, in: text) else { return nil }
        return String(text[swiftRange])
    }

    private func extractEventType(from text: String) -> String? {
        extractKnownTerms(from: text, terms: Self.knownEvents).first
    }

    private func extractKnownTerms(from text: String, terms: [String]) -> [String] {
        let normalized = text.lowercased()
        return terms.filter { normalized.contains($0) }
    }

    private func extractPatternCaptures(from text: String, patterns: [String]) -> [String] {
        var captures: [String] = []

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)

            for match in matches where match.numberOfRanges > 1 {
                let captureRange = match.range(at: 1)
                guard let swiftRange = Range(captureRange, in: text) else { continue }
                let captured = text[swiftRange]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                if !captured.isEmpty {
                    captures.append(captured)
                }
            }
        }

        return Array(Set(captures)).sorted()
    }
}
