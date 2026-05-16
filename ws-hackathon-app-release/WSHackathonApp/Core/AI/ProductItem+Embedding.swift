//
//  ProductItem+Embedding.swift
//  WSHackathonApp
//
//  Synthesizes a rich text description from structured product fields so that
//  NLEmbedding can produce a meaningful semantic vector. The richer this string,
//  the better cosine-similarity matching will work.
//

import Foundation

extension ProductItem {

    /// A human-readable description assembled from all available structured fields.
    /// Used as the input to NLEmbedding — never shown directly in the UI.
    var embeddableDescription: String {
        var parts: [String] = []

        parts.append(title)

        if let shortDesc = shortDescription, !shortDesc.isEmpty {
            parts.append(shortDesc)
        }

        if let semanticDescription, !semanticDescription.isEmpty {
            parts.append(semanticDescription)
        }

        if let brand = brand, !brand.isEmpty {
            parts.append("brand: \(cleanToken(brand))")
        }

        if let material = material, !material.isEmpty {
            parts.append("material: \(cleanToken(material))")
        }

        if let type = productType, !type.isEmpty {
            parts.append("category: \(cleanToken(type))")
        }

        if let coll = collection, !coll.isEmpty {
            parts.append("collection: \(cleanToken(coll))")
        }

        if let color, !color.isEmpty {
            parts.append("color: \(cleanToken(color))")
        }

        if !eventTags.isEmpty {
            parts.append("events: \(eventTags.map(cleanToken).joined(separator: ", "))")
        }

        if !slotHints.isEmpty {
            parts.append("use cases: \(slotHints.map(cleanToken).joined(separator: ", "))")
        }

        if !styleTags.isEmpty {
            parts.append("style: \(styleTags.map(cleanToken).joined(separator: ", "))")
        }

        if !settingTags.isEmpty {
            parts.append("settings: \(settingTags.map(cleanToken).joined(separator: ", "))")
        }

        if !essentialForEvents.isEmpty {
            parts.append("essential for: \(essentialForEvents.map(cleanToken).joined(separator: ", "))")
        }

        if let price = price {
            let formatted = String(format: "$%.2f", price)
            parts.append("priced at \(formatted)")
            parts.append("price band: \(priceBand(for: price))")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - DTO-level description (richer — used during indexing)

extension ProductItemDTO {

    /// Full embeddable description built from all DTO fields.
    /// This is what should be embedded at index time.
    var embeddableDescription: String {
        var parts: [String] = []

        parts.append(name)

        if let shortName = shortName, !shortName.isEmpty {
            parts.append(shortName)
        }

        if let brand = properties?.brand, !brand.isEmpty {
            let cleanBrand = cleanToken(brand)
            parts.append("brand: \(cleanBrand)")
        }

        if let material = properties?.material, !material.isEmpty {
            let cleanMaterial = cleanToken(material)
            parts.append("material: \(cleanMaterial)")
        }

        if let productType = properties?.productType, !productType.isEmpty {
            let cleanType = cleanToken(productType)
            parts.append("category: \(cleanType)")
        }

        if let color = properties?.color, !color.isEmpty {
            let cleanColor = cleanToken(color)
            parts.append("color: \(cleanColor)")
        }

        if let pattern = properties?.pattern, !pattern.isEmpty {
            let cleanPattern = cleanToken(pattern)
            parts.append("style: \(cleanPattern)")
        }

        if let collection = properties?.collection, !collection.isEmpty {
            let cleanCollection = cleanToken(collection)
            parts.append("collection: \(cleanCollection)")
        }

        if let regularPrice = price?.regularPrice {
            parts.append(String(format: "priced at $%.2f", regularPrice))
            parts.append("price band: \(priceBand(for: regularPrice))")
        }

        if let description, !description.isEmpty {
            parts.append(description)
        }

        if let eventTags, !eventTags.isEmpty {
            parts.append("events: \(eventTags.map(cleanToken).joined(separator: ", "))")
        }

        if let slotHints, !slotHints.isEmpty {
            parts.append("use cases: \(slotHints.map(cleanToken).joined(separator: ", "))")
        }

        if let styleTags, !styleTags.isEmpty {
            parts.append("style: \(styleTags.map(cleanToken).joined(separator: ", "))")
        }

        if let settingTags, !settingTags.isEmpty {
            parts.append("settings: \(settingTags.map(cleanToken).joined(separator: ", "))")
        }

        if let essentialForEvents, !essentialForEvents.isEmpty {
            parts.append("essential for: \(essentialForEvents.map(cleanToken).joined(separator: ", "))")
        }

        if properties?.isFood == "true" {
            parts.append("food item")
        }
        if properties?.isFurniture == "true" {
            parts.append("furniture")
        }

        return parts.joined(separator: ", ")
    }
}

private func cleanToken(_ value: String) -> String {
    value
        .replacingOccurrences(of: "-parent/", with: " ")
        .replacingOccurrences(of: "[", with: "")
        .replacingOccurrences(of: "]", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: "/", with: " ")
        .replacingOccurrences(of: "_", with: " ")
}

private func priceBand(for price: Double) -> String {
    switch price {
    case ..<30:
        return "budget"
    case ..<100:
        return "mid range"
    case ..<250:
        return "premium"
    default:
        return "luxury"
    }
}
