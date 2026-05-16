//
//  Model.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation

enum TabItem: Int, CaseIterable, Identifiable {
    case home = 0
    case registry
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .registry: return "Registry"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .registry: return "list.bullet"
        }
    }
    
    static func from(rawValue: Int) -> TabItem? {
        return TabItem(rawValue: rawValue)
    }
}

