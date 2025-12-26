//
//  Style.swift
//  CladsRendererFramework
//

import Foundation

/// Style definition with optional single-parent inheritance
public struct Style: Codable {
    // Inheritance - single parent style ID
    public let inherits: String?

    // Typography
    public let fontFamily: String?
    public let fontSize: CGFloat?
    public let fontWeight: FontWeight?
    public let textColor: String?
    public let textAlignment: TextAlignment?

    // Background & Border
    public let backgroundColor: String?
    public let cornerRadius: CGFloat?
    public let borderWidth: CGFloat?
    public let borderColor: String?

    // Sizing
    public let width: CGFloat?
    public let height: CGFloat?
    public let minWidth: CGFloat?
    public let minHeight: CGFloat?
    public let maxWidth: CGFloat?
    public let maxHeight: CGFloat?

    // Padding (internal)
    public let paddingTop: CGFloat?
    public let paddingBottom: CGFloat?
    public let paddingLeading: CGFloat?
    public let paddingTrailing: CGFloat?
    public let paddingHorizontal: CGFloat?
    public let paddingVertical: CGFloat?

    public init(
        inherits: String? = nil,
        fontFamily: String? = nil,
        fontSize: CGFloat? = nil,
        fontWeight: FontWeight? = nil,
        textColor: String? = nil,
        textAlignment: TextAlignment? = nil,
        backgroundColor: String? = nil,
        cornerRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: String? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        paddingTop: CGFloat? = nil,
        paddingBottom: CGFloat? = nil,
        paddingLeading: CGFloat? = nil,
        paddingTrailing: CGFloat? = nil,
        paddingHorizontal: CGFloat? = nil,
        paddingVertical: CGFloat? = nil
    ) {
        self.inherits = inherits
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.paddingLeading = paddingLeading
        self.paddingTrailing = paddingTrailing
        self.paddingHorizontal = paddingHorizontal
        self.paddingVertical = paddingVertical
    }
}

// MARK: - Font Weight

public enum FontWeight: String, Codable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
}

// MARK: - Text Alignment

public enum TextAlignment: String, Codable {
    case leading
    case center
    case trailing
}
