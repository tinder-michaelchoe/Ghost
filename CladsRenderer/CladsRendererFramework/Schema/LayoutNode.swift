//
//  LayoutNode.swift
//  CladsRendererFramework
//

import Foundation

/// A node in the layout tree - can be either a layout container or a component
public enum LayoutNode: Codable {
    case layout(Layout)
    case component(Component)
    case spacer

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "vstack", "hstack", "zstack":
            self = .layout(try Layout(from: decoder))
        case "spacer":
            self = .spacer
        default:
            // Assume it's a component
            self = .component(try Component(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .layout(let layout):
            try layout.encode(to: encoder)
        case .component(let component):
            try component.encode(to: encoder)
        case .spacer:
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("spacer", forKey: .type)
        }
    }
}

/// Layout container types
public enum LayoutType: String, Codable {
    case vstack
    case hstack
    case zstack
}

/// Horizontal alignment options
public enum HorizontalAlignment: String, Codable {
    case leading
    case center
    case trailing
}

/// Vertical alignment options
public enum VerticalAlignment: String, Codable {
    case top
    case center
    case bottom
}

/// Alignment for ZStack
public struct Alignment: Codable {
    public let horizontal: HorizontalAlignment?
    public let vertical: VerticalAlignment?

    public init(horizontal: HorizontalAlignment? = nil, vertical: VerticalAlignment? = nil) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

/// Padding specification
public struct Padding: Codable {
    public let top: CGFloat?
    public let bottom: CGFloat?
    public let leading: CGFloat?
    public let trailing: CGFloat?
    public let horizontal: CGFloat?
    public let vertical: CGFloat?

    public init(
        top: CGFloat? = nil,
        bottom: CGFloat? = nil,
        leading: CGFloat? = nil,
        trailing: CGFloat? = nil,
        horizontal: CGFloat? = nil,
        vertical: CGFloat? = nil
    ) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
        self.horizontal = horizontal
        self.vertical = vertical
    }

    /// Resolves the padding values, preferring specific values over general ones
    public var resolvedTop: CGFloat { top ?? vertical ?? 0 }
    public var resolvedBottom: CGFloat { bottom ?? vertical ?? 0 }
    public var resolvedLeading: CGFloat { leading ?? horizontal ?? 0 }
    public var resolvedTrailing: CGFloat { trailing ?? horizontal ?? 0 }
}

/// Layout container that holds children
public struct Layout: Codable {
    public let type: LayoutType
    public let alignment: Alignment?
    public let horizontalAlignment: HorizontalAlignment?
    public let spacing: CGFloat?
    public let padding: Padding?
    public let children: [LayoutNode]

    enum CodingKeys: String, CodingKey {
        case type, alignment, spacing, padding, children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(LayoutType.self, forKey: .type)
        spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
        children = try container.decodeIfPresent([LayoutNode].self, forKey: .children) ?? []

        // Try to decode alignment as Alignment first (for zstack)
        if let alignmentObj = try? container.decodeIfPresent(Alignment.self, forKey: .alignment) {
            alignment = alignmentObj
            horizontalAlignment = nil
        } else if let alignStr = try? container.decodeIfPresent(HorizontalAlignment.self, forKey: .alignment) {
            // For vstack/hstack, alignment is a simple string
            horizontalAlignment = alignStr
            alignment = nil
        } else {
            alignment = nil
            horizontalAlignment = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(spacing, forKey: .spacing)
        try container.encodeIfPresent(padding, forKey: .padding)
        try container.encode(children, forKey: .children)
        if let alignment = alignment {
            try container.encode(alignment, forKey: .alignment)
        } else if let horizontalAlignment = horizontalAlignment {
            try container.encode(horizontalAlignment, forKey: .alignment)
        }
    }

    public init(
        type: LayoutType,
        alignment: Alignment? = nil,
        horizontalAlignment: HorizontalAlignment? = nil,
        spacing: CGFloat? = nil,
        padding: Padding? = nil,
        children: [LayoutNode]
    ) {
        self.type = type
        self.alignment = alignment
        self.horizontalAlignment = horizontalAlignment
        self.spacing = spacing
        self.padding = padding
        self.children = children
    }
}
