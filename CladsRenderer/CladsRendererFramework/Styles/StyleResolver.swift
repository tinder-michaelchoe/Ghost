//
//  StyleResolver.swift
//  CladsRendererFramework
//

import Foundation
import SwiftUI

/// Resolves styles with single-parent inheritance support
public struct StyleResolver {
    private let styles: [String: Style]

    public init(styles: [String: Style]?) {
        self.styles = styles ?? [:]
    }

    /// Resolve a style by ID, following the inheritance chain
    public func resolve(_ styleId: String?) -> ResolvedStyle {
        guard let styleId = styleId, let style = styles[styleId] else {
            return ResolvedStyle()
        }
        return resolve(style: style, visited: [])
    }

    private func resolve(style: Style, visited: Set<String>) -> ResolvedStyle {
        // Start with parent style if inheriting
        var resolved: ResolvedStyle
        if let parentId = style.inherits,
           !visited.contains(parentId),
           let parentStyle = styles[parentId] {
            var newVisited = visited
            newVisited.insert(parentId)
            resolved = resolve(style: parentStyle, visited: newVisited)
        } else {
            resolved = ResolvedStyle()
        }

        // Override with current style values
        resolved.merge(from: style)
        return resolved
    }
}

/// A fully resolved style with all inherited values merged
public struct ResolvedStyle {
    // Typography
    public var fontFamily: String?
    public var fontSize: CGFloat?
    public var fontWeight: Font.Weight?
    public var textColor: Color?
    public var textAlignment: SwiftUI.TextAlignment?

    // Background & Border
    public var backgroundColor: Color?
    public var cornerRadius: CGFloat?
    public var borderWidth: CGFloat?
    public var borderColor: Color?

    // Sizing
    public var width: CGFloat?
    public var height: CGFloat?
    public var minWidth: CGFloat?
    public var minHeight: CGFloat?
    public var maxWidth: CGFloat?
    public var maxHeight: CGFloat?

    // Padding
    public var paddingTop: CGFloat?
    public var paddingBottom: CGFloat?
    public var paddingLeading: CGFloat?
    public var paddingTrailing: CGFloat?

    public init() {}

    mutating func merge(from style: Style) {
        if let v = style.fontFamily { fontFamily = v }
        if let v = style.fontSize { fontSize = v }
        if let v = style.fontWeight { fontWeight = v.toSwiftUI() }
        if let v = style.textColor { textColor = Color(hex: v) }
        if let v = style.textAlignment { textAlignment = v.toSwiftUI() }
        if let v = style.backgroundColor { backgroundColor = Color(hex: v) }
        if let v = style.cornerRadius { cornerRadius = v }
        if let v = style.borderWidth { borderWidth = v }
        if let v = style.borderColor { borderColor = Color(hex: v) }
        if let v = style.width { width = v }
        if let v = style.height { height = v }
        if let v = style.minWidth { minWidth = v }
        if let v = style.minHeight { minHeight = v }
        if let v = style.maxWidth { maxWidth = v }
        if let v = style.maxHeight { maxHeight = v }

        // Padding resolution: specific > general
        if let v = style.paddingTop { paddingTop = v }
        else if let v = style.paddingVertical { paddingTop = v }

        if let v = style.paddingBottom { paddingBottom = v }
        else if let v = style.paddingVertical { paddingBottom = v }

        if let v = style.paddingLeading { paddingLeading = v }
        else if let v = style.paddingHorizontal { paddingLeading = v }

        if let v = style.paddingTrailing { paddingTrailing = v }
        else if let v = style.paddingHorizontal { paddingTrailing = v }
    }

    /// Get the font with size and weight applied
    public var font: Font? {
        guard fontSize != nil || fontWeight != nil else { return nil }
        var font = Font.system(size: fontSize ?? 17)
        if let weight = fontWeight {
            font = font.weight(weight)
        }
        return font
    }
}

// MARK: - SwiftUI Conversions

extension FontWeight {
    func toSwiftUI() -> Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

extension TextAlignment {
    func toSwiftUI() -> SwiftUI.TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
