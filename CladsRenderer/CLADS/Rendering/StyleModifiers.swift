//
//  StyleModifiers.swift
//  CLADS
//
//  SwiftUI View extensions for applying IR.Style properties.
//

import SwiftUI

// MARK: - Style Modifiers

public extension View {
    func applyTextStyle(_ style: IR.Style) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.textColor)
            .multilineTextAlignment(style.textAlignment ?? .leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    func applyContainerStyle(_ style: IR.Style) -> some View {
        self
            .padding(.top, style.paddingTop ?? 0)
            .padding(.bottom, style.paddingBottom ?? 0)
            .padding(.leading, style.paddingLeading ?? 0)
            .padding(.trailing, style.paddingTrailing ?? 0)
            .frame(width: style.width, height: style.height)
            .frame(minWidth: style.minWidth, minHeight: style.minHeight)
            .frame(maxWidth: style.maxWidth, maxHeight: style.maxHeight)
            .background(style.backgroundColor ?? Color.clear)
            .cornerRadius(style.cornerRadius ?? 0)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius ?? 0)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: style.borderWidth ?? 0)
            )
    }
}
