//
//  CustomImageLoader.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI
import Combine

final class CustomImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private var lastUrl: URL?
    
    @MainActor
    func load(url: URL?) async {
        guard let url, url != lastUrl else { return }
        lastUrl = url
        image = nil
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                self.image = img
            }
        } catch {
            if !(error is CancellationError) {
                print("Image load failed:", error)
            }
        }
    }
}
