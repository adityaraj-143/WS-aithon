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

        // Core identity
        parts.append(title)

        // We need the DTO data, but ProductItem is already flattened.
        // We extend using the DTO-sourced properties that survive into ProductItem.
        // Additional richness comes from the DTO extension below.

        if let price = price {
            let formatted = String(format: "$%.2f", price)
            parts.append("priced at \(formatted)")
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

        // Name
        parts.append(name)

        // Brand
        if let brand = properties?.brand, !brand.isEmpty {
            let cleanBrand = brand
                .replacingOccurrences(of: "-parent/", with: " ")
                .replacingOccurrences(of: "-", with: " ")
            parts.append("brand: \(cleanBrand)")
        }

        // Material
        if let material = properties?.material, !material.isEmpty {
            let cleanMaterial = material
                .replacingOccurrences(of: "-parent/", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
            parts.append("material: \(cleanMaterial)")
        }

        // Product type / category
        if let productType = properties?.productType, !productType.isEmpty {
            let cleanType = productType.replacingOccurrences(of: "-", with: " ")
            parts.append("category: \(cleanType)")
        }

        // Color
        if let color = properties?.color, !color.isEmpty {
            let cleanColor = color
                .replacingOccurrences(of: "-parent/", with: " ")
                .replacingOccurrences(of: "-", with: " ")
            parts.append("color: \(cleanColor)")
        }

        // Pattern / style domain (e.g. cookware, tabletop, electrics)
        if let pattern = properties?.pattern, !pattern.isEmpty {
            let cleanPattern = pattern
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
            parts.append("style: \(cleanPattern)")
        }

        // Collection
        if let collection = properties?.collection, !collection.isEmpty {
            let cleanCollection = collection.replacingOccurrences(of: "-", with: " ")
            parts.append("collection: \(cleanCollection)")
        }

        // Price
        if let regularPrice = price?.regularPrice {
            parts.append(String(format: "priced at $%.2f", regularPrice))
        }

        // Food / furniture flags for semantic distinction
        if properties?.isFood == "true" {
            parts.append("food item")
        }
        if properties?.isFurniture == "true" {
            parts.append("furniture")
        }

        return parts.joined(separator: ", ")
    }
}
