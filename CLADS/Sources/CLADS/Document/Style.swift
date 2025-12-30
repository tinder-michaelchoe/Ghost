//
//  Style.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Style

extension Document {
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

        // Image
        public let tintColor: String?

        // Sizing
        public let width: CGFloat?
        public let height: CGFloat?
        public let minWidth: CGFloat?
        public let minHeight: CGFloat?
        public let maxWidth: CGFloat?
        public let maxHeight: CGFloat?

        // Padding (internal)
        public let padding: Padding?

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
            tintColor: String? = nil,
            width: CGFloat? = nil,
            height: CGFloat? = nil,
            minWidth: CGFloat? = nil,
            minHeight: CGFloat? = nil,
            maxWidth: CGFloat? = nil,
            maxHeight: CGFloat? = nil,
            padding: Padding? = nil
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
            self.tintColor = tintColor
            self.width = width
            self.height = height
            self.minWidth = minWidth
            self.minHeight = minHeight
            self.maxWidth = maxWidth
            self.maxHeight = maxHeight
            self.padding = padding
        }
    }
}

// MARK: - Font Weight

extension Document {
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
}

// MARK: - Text Alignment

extension Document {
    public enum TextAlignment: String, Codable {
        case leading
        case center
        case trailing
    }
}
