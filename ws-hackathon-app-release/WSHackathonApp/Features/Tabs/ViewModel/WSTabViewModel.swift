//
//  WSTabViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 03/04/26.
//

import Foundation
import Combine
import SwiftUI

enum HomeRoute: Hashable {
    case detail(ProductItem)
}

@MainActor
class WSTabBarViewModel: ObservableObject {
    
    @Published var selectedTab: TabItem = .home
    @Published var homePath: [HomeRoute] = []

    
    var tabs: [TabItem] {
        TabItem.allCases
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    func navigateToDetail(_ product: ProductItem) {
        homePath.append(.detail(product))
    }
}
