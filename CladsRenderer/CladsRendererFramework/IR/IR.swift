//
//  IR.swift
//  CladsRendererFramework
//
//  Namespace for Intermediate Representation types.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - IR Namespace

/// Namespace for Intermediate Representation (IR) types.
///
/// Types in this namespace represent the resolved, render-ready structures
/// after processing from `Document.*` types. These are consumed by renderers.
///
/// Usage:
/// ```swift
/// let style: IR.Style = resolver.resolve(styleId)
/// let section: IR.Section = ...
/// ```
public enum IR {}

// MARK: - IR.Style

extension IR {
    /// A fully resolved style with all inherited values merged.
    ///
    /// This is the IR representation of a style, ready for rendering.
    public struct Style {
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

        mutating func merge(from style: Document.Style) {
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
}

// MARK: - IR.Section

extension IR {
    /// A resolved section within a SectionLayoutNode
    public struct Section {
        public let id: String?
        public let layoutType: SectionType
        public let header: RenderNode?
        public let footer: RenderNode?
        public let stickyHeader: Bool
        public let config: SectionConfig
        public let children: [RenderNode]

        public init(
            id: String? = nil,
            layoutType: SectionType,
            header: RenderNode? = nil,
            footer: RenderNode? = nil,
            stickyHeader: Bool = false,
            config: SectionConfig = SectionConfig(),
            children: [RenderNode] = []
        ) {
            self.id = id
            self.layoutType = layoutType
            self.header = header
            self.footer = footer
            self.stickyHeader = stickyHeader
            self.config = config
            self.children = children
        }
    }
}

// MARK: - IR.SectionType

extension IR {
    /// Section type for rendering
    public enum SectionType {
        case horizontal  // Horizontally scrolling row
        case list        // Vertical list (table-like)
        case grid(columns: ColumnConfig)  // Grid layout
        case flow        // Flow/wrapping layout
    }
}

// MARK: - IR.ColumnConfig

extension IR {
    /// Resolved column configuration for grids
    public enum ColumnConfig: Equatable {
        case fixed(Int)
        case adaptive(minWidth: CGFloat)
    }
}

// MARK: - IR.SectionConfig

extension IR {
    /// Resolved configuration for a section
    public struct SectionConfig {
        public let itemSpacing: CGFloat
        public let lineSpacing: CGFloat
        public let contentInsets: NSDirectionalEdgeInsets

        // Horizontal section
        public let showsIndicators: Bool
        public let isPagingEnabled: Bool

        // List section
        public let showsDividers: Bool

        public init(
            itemSpacing: CGFloat = 8,
            lineSpacing: CGFloat = 8,
            contentInsets: NSDirectionalEdgeInsets = .zero,
            showsIndicators: Bool = false,
            isPagingEnabled: Bool = false,
            showsDividers: Bool = true
        ) {
            self.itemSpacing = itemSpacing
            self.lineSpacing = lineSpacing
            self.contentInsets = contentInsets
            self.showsIndicators = showsIndicators
            self.isPagingEnabled = isPagingEnabled
            self.showsDividers = showsDividers
        }
    }
}

// MARK: - UIKit Extensions for IR.Style

extension IR.Style {
    /// Get the UIFont with size and weight applied
    public var uiFont: UIFont? {
        guard fontSize != nil || fontWeight != nil else { return nil }
        let size = fontSize ?? 17
        if let weight = fontWeight {
            return UIFont.systemFont(ofSize: size, weight: weight.toUIKit())
        }
        return UIFont.systemFont(ofSize: size)
    }
}
