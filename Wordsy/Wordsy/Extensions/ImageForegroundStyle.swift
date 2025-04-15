//
//  ImageForegroundStyle.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//


import SwiftUI

struct ImageForegroundStyle: ViewModifier {
    let image: Image

    func body(content: Content) -> some View {
        ZStack {
            content
                .foregroundColor(.clear) // Make original text transparent
                .overlay(
                    image
                        .resizable()
                        .scaledToFill()
                        .mask(content)
                )
        }
    }
}

extension View {
    func imageForegroundStyle(_ image: Image) -> some View {
        modifier(ImageForegroundStyle(image: image))
    }
}
