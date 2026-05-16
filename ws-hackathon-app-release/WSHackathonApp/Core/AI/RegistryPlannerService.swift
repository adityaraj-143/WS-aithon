//
//  RegistryPlannerService.swift
//  WSHackathonApp
//

import Foundation

struct RegistryEventTemplate {
    let eventType: String
    let requiredSlots: [String]
    let optionalSlots: [String]

    static func template(for eventType: String?) -> RegistryEventTemplate {
        switch eventType?.lowercased() {
        case "birthday":
            return RegistryEventTemplate(
                eventType: "birthday",
                requiredSlots: ["serveware", "drinkware", "tabletop"],
                optionalSlots: ["decor", "barware", "food prep"]
            )
        case "wedding", "anniversary":
            return RegistryEventTemplate(
                eventType: "wedding",
                requiredSlots: ["cookware", "serveware", "drinkware"],
                optionalSlots: ["tabletop", "coffee", "homekeeping"]
            )
        case "housewarming":
            return RegistryEventTemplate(
                eventType: "housewarming",
                requiredSlots: ["cookware", "serveware", "homekeeping"],
                optionalSlots: ["pantry", "coffee", "drinkware"]
            )
        case "brunch":
            return RegistryEventTemplate(
                eventType: "brunch",
                requiredSlots: ["coffee", "tabletop", "serveware"],
                optionalSlots: ["drinkware", "pantry", "decor"]
            )
        case "dinner":
            return RegistryEventTemplate(
                eventType: "dinner",
                requiredSlots: ["cookware", "serveware", "tabletop"],
                optionalSlots: ["drinkware", "decor", "food prep"]
            )
        default:
            return RegistryEventTemplate(
                eventType: "general",
                requiredSlots: [],
                optionalSlots: ["cookware", "serveware", "drinkware", "tabletop", "coffee", "homekeeping"]
            )
        }
    }
}

final class RegistryPlannerService: @unchecked Sendable {
    private let vectorStore: ProductVectorStore
    private let parser: PromptParser
    private let planBuilder: RegistryPlanBuilder
    private(set) var conversationState: RegistryConversationState

    init(
        vectorStore: ProductVectorStore = ProductVectorStore(),
        parser: PromptParser = PromptParser(),
        planBuilder: RegistryPlanBuilder = RegistryPlanBuilder(),
        conversationState: RegistryConversationState = .empty
    ) {
        self.vectorStore = vectorStore
        self.parser = parser
        self.planBuilder = planBuilder
        self.conversationState = conversationState
    }

    var hasIndex: Bool {
        vectorStore.hasIndex
    }

    func buildIndex(dtos: [ProductItemDTO]) {
        vectorStore.index(dtos: dtos)
    }

    func resetConversation() {
        conversationState = .empty
    }

    func plan(prompt: String, topK: Int = 20, minScore: Double = 0.1) -> PlannedRegistryResponse {
        let intent = parser.parse(prompt)
        conversationState.merge(intent: intent)

        let browseProducts = filterBrowseProducts(
            vectorStore.search(prompt: prompt, topK: topK, minScore: minScore),
            state: conversationState
        )

        let registryPlan = planBuilder.build(
            from: browseProducts,
            intent: intent,
            state: conversationState
        )

        return PlannedRegistryResponse(
            intent: intent,
            browseProducts: browseProducts,
            registryPlan: registryPlan
        )
    }

    private func filterBrowseProducts(
        _ candidates: [ScoredProduct],
        state: RegistryConversationState
    ) -> [ScoredProduct] {
        candidates.filter { candidate in
            !state.ownedKeywords.contains(where: { matches(keyword: $0, product: candidate.product) }) &&
            !state.excludedKeywords.contains(where: { matches(keyword: $0, product: candidate.product) })
        }
    }

    private func matches(keyword: String, product: ProductItem) -> Bool {
        let normalizedKeyword = normalize(keyword)
        var searchable = [
            product.title,
            product.shortDescription ?? "",
            product.semanticDescription ?? "",
            product.collection ?? "",
            product.brand ?? "",
            product.material ?? "",
            product.productType ?? ""
        ]
        searchable.append(contentsOf: product.slotHints)
        searchable.append(contentsOf: product.settingTags)
        searchable.append(contentsOf: product.eventTags)
        searchable.append(contentsOf: product.styleTags)

        return searchable.contains { normalize($0).contains(normalizedKeyword) }
    }

    private func normalize(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "-", with: " ")
    }
}
