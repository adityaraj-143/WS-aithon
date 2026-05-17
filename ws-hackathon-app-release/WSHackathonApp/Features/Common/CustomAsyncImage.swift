//
//  CustomAsyncImage.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 06/04/26.
//

import SwiftUI
import UIKit

struct CustomAsyncImage: View {
    let url: URL?
    @StateObject private var loader = CustomImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Color.brandAccentWash
                ProgressView()
                    .tint(.brandPrimary)
            }
        }
        .task(id: url) {
            await loader.load(url: url)
        }
    }
}
