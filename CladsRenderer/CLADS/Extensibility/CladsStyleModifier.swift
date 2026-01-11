//
//  CladsStyleModifier.swift
//  CLADS
//
//  SwiftUI view modifier for applying CLADS styles to custom components.
//

import Foundation
import SwiftUI

// MARK: - CLADS Style Modifier

/// View modifier that applies CLADS IR.Style to a SwiftUI view.
///
/// This allows custom components to use the same styling system as built-in components.
///
/// Example:
/// ```swift
/// MyCustomView()
///     .applyCladsStyle(context.style)
/// ```
public struct CladsStyleModifier: ViewModifier {
    let style: IR.Style

    public init(style: IR.Style) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .applyFont(style)
            .applyForegroundColor(style)
            .applyBackground(style)
            .applyCornerRadius(style)
            .applyBorder(style)
            .applyFrame(style)
    }
}

// MARK: - View Extension

extension View {
    /// Apply a CLADS style to this view
    public func applyCladsStyle(_ style: IR.Style) -> some View {
        modifier(CladsStyleModifier(style: style))
    }
}

// MARK: - Style Application Helpers

private extension View {
    @ViewBuilder
    func applyFont(_ style: IR.Style) -> some View {
        if let fontSize = style.fontSize {
            let weight = style.fontWeight ?? .regular
            self.font(.system(size: fontSize, weight: weight))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyForegroundColor(_ style: IR.Style) -> some View {
        if let textColor = style.textColor {
            self.foregroundColor(textColor)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyBackground(_ style: IR.Style) -> some View {
        if let backgroundColor = style.backgroundColor {
            self.background(backgroundColor)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyCornerRadius(_ style: IR.Style) -> some View {
        if let cornerRadius = style.cornerRadius {
            self.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyBorder(_ style: IR.Style) -> some View {
        if let borderColor = style.borderColor, let borderWidth = style.borderWidth {
            if let cornerRadius = style.cornerRadius {
                self.overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            } else {
                self.border(borderColor, width: borderWidth)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func applyFrame(_ style: IR.Style) -> some View {
        let width = style.width
        let height = style.height
        let minWidth = style.minWidth
        let maxWidth = style.maxWidth
        let minHeight = style.minHeight
        let maxHeight = style.maxHeight

        if width != nil || height != nil || minWidth != nil || maxWidth != nil || minHeight != nil || maxHeight != nil {
            self.frame(
                minWidth: minWidth,
                idealWidth: width,
                maxWidth: maxWidth,
                minHeight: minHeight,
                idealHeight: height,
                maxHeight: maxHeight
            )
        } else {
            self
        }
    }
}

