//
//  ProductVectorStore.swift
//  WSHackathonApp
//
//  On-device semantic index using Apple's NLEmbedding (NaturalLanguage framework).
//  No network calls. No third-party libraries.
//
//  Usage:
//    1. Call `index(dtos:)` once after fetching products from the API.
//    2. Call `search(prompt:topK:)` to get semantically similar products.
//

import Foundation
import NaturalLanguage

// MARK: - Internal storage unit

private struct ProductVector {
    let product: ProductItem
    /// Raw embedding vector from NLEmbedding (typically 512-dimensional)
    let vector: [Double]
}

// MARK: - ProductVectorStore

final class ProductVectorStore: @unchecked Sendable {

    // MARK: - State

    private var entries: [ProductVector] = []
    private var isIndexed = false

    /// Whether the store has been populated and is ready to search.
    var hasIndex: Bool { isIndexed && !entries.isEmpty }

    // MARK: - Indexing

    /// Builds the in-memory vector index from a list of product DTOs.
    /// Call this on a background Task — NLEmbedding's first invocation can take ~300ms.
    ///
    /// - Parameter dtos: Full product DTOs (richer descriptions than ProductItem).
    func index(dtos: [ProductItemDTO]) {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            print("⚠️ [VectorStore] NLEmbedding not available on this device/simulator.")
            return
        }

        entries = dtos.compactMap { dto in
            let description = dto.embeddableDescription
            guard let vec = embedding.vector(for: description) else {
                print("⚠️ [VectorStore] Could not embed: \(dto.name)")
                return nil
            }
            let product = ProductItem(from: dto)
            return ProductVector(product: product, vector: vec)
        }

        isIndexed = true
        print("✅ [VectorStore] Indexed \(entries.count) products.")
    }

    // MARK: - Search

    /// Returns the top-K most semantically similar products to the given prompt.
    ///
    /// - Parameters:
    ///   - prompt: Free-text user query.
    ///   - topK: Maximum number of results to return (default: all products ranked).
    ///   - minScore: Minimum cosine similarity threshold (0–1). Default 0.0 = no filtering.
    /// - Returns: Ranked list of `ScoredProduct`, highest score first.
    func search(prompt: String, topK: Int = 20, minScore: Double = 0.0) -> [ScoredProduct] {
        guard hasIndex else {
            print("⚠️ [VectorStore] Index not built. Call index(dtos:) first.")
            return []
        }

        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english),
              let queryVector = embedding.vector(for: prompt) else {
            print("⚠️ [VectorStore] Could not embed query: \(prompt)")
            return []
        }

        return entries
            .compactMap { entry -> ScoredProduct? in
                let score = cosineSimilarity(queryVector, entry.vector)
                guard score >= minScore else { return nil }
                return ScoredProduct(product: entry.product, score: score)
            }
            .sorted { $0.score > $1.score }
            .prefix(topK)
            .map { $0 }
    }

    // MARK: - Math

    /// Cosine similarity between two equal-length vectors. Returns value in [-1, 1].
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dot: Double = 0
        var magA: Double = 0
        var magB: Double = 0

        for i in 0..<a.count {
            dot  += a[i] * b[i]
            magA += a[i] * a[i]
            magB += b[i] * b[i]
        }

        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0 }
        return dot / denom
    }
}
