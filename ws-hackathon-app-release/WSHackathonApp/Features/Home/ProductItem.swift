//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
struct ProductItem: Identifiable, Hashable {
    let id: String
    let title: String
    let price: Double?
    let retailPrice: Double?
    let path: String?
    
    // Detailed fields
    let brand: String?
    let shortDescription: String?
    let availability: String?
    let deliveryEstimate: String?
    let material: String?
    let collection: String?
    
    // New fields for UI design
    let productType: String?
    let canGiftWrap: Bool
    let isFreeShipping: Bool
    let color: String?
    
    var imageURL: URL? {
        if let imageUrl = path {
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProductItem, rhs: ProductItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension ProductItem {
    init(from dto: ProductItemDTO) {
        self.id = dto.id
        self.title = dto.name
        
        // Price formatting: use regularPrice or sellingPrice if available
        if let priceValue = dto.price?.sellingPrice {
            self.price = priceValue
        } else if let priceValue = dto.price?.regularPrice {
            self.price = priceValue
        } else {
            self.price = 0.0
        }
        self.retailPrice = dto.price?.retailPrice
        
        // Image: first ProductImage path if available
        if let firstImage = dto.media?.images?.first?.path {
            self.path = firstImage
        } else {
            self.path = nil
        }
        
        // Detailed fields mapping
        self.brand = dto.properties?.brand
        self.shortDescription = dto.shortName
        self.availability = dto.availability
        self.deliveryEstimate = dto.deliveryEstimate
        self.material = dto.properties?.material
        self.collection = dto.properties?.collection
        
        self.productType = dto.properties?.productType
        self.canGiftWrap = (dto.properties?.canGiftWrap?.lowercased() == "true")
        self.isFreeShipping = dto.freeShip ?? false
        
        // Color parsing e.g. "green-parent/basil" -> "Basil Green"
        if let colorRaw = dto.properties?.color {
            let parts = colorRaw.split(separator: "/")
            if parts.count > 1 {
                let mainColor = parts[0].replacingOccurrences(of: "-parent", with: "").capitalized
                let shade = parts[1].capitalized
                if mainColor.lowercased() == shade.lowercased() {
                    self.color = mainColor
                } else {
                    self.color = "\(shade) \(mainColor)"
                }
            } else {
                self.color = colorRaw.capitalized
            }
        } else {
            self.color = nil
        }
    }
}


