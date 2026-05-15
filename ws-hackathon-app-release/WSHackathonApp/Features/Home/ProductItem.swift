//
//  ProductItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
struct ProductItem: Identifiable {
    let id: String
    let title: String
    let price: Double?
    let path: String?
    let description: String?
    let eventTags: [String]
    let slotHints: [String]
    let styleTags: [String]
    let settingTags: [String]
    let essentialForEvents: [String]
    let color: String?
    
    var imageURL: URL? {
        if let imageUrl = path {
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
    }
}

extension ProductItem {
    init(from dto: ProductItemDTO) {
        self.id = dto.id
        self.title = dto.name
        
        // Price formatting: use regularPrice if available
        if let priceValue = dto.price?.regularPrice {
            self.price = priceValue
        } else {
            self.price = 0.0
        }
        
        // Image: first ProductImage path if available
        if let firstImage = dto.media?.images?.first?.path {
            self.path = firstImage
        } else {
            self.path = nil
        }

        self.description = dto.description
        self.eventTags = dto.eventTags ?? []
        self.slotHints = dto.slotHints ?? []
        self.styleTags = dto.styleTags ?? []
        self.settingTags = dto.settingTags ?? []
        self.essentialForEvents = dto.essentialForEvents ?? []
        self.color = dto.properties?.color
    }
}
