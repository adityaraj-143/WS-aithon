//
//  CartItem.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import Foundation

struct CartItem: Identifiable, Hashable {
    let id: String
    let title: String
    let price: Double
    let path: String?
    var quantity: Int
    
    // Registry metadata for grouping
    let registryId: String?
    let registryName: String?
    let registryEventDate: Date?
    
    var imageURL: URL? {
        if let imageUrl = path {
            return URL(string: AppConstants.API.imageBasePath + imageUrl)
        }
        return nil
    }
    
    init(id: String,
         title: String,
         price: Double,
         path: String?,
         quantity: Int,
         registryId: String? = nil,
         registryName: String? = nil,
         registryEventDate: Date? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.path = path
        self.quantity = quantity
        self.registryId = registryId
        self.registryName = registryName
        self.registryEventDate = registryEventDate
    }
}
