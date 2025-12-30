//
//  SectionLayout.swift
//  CladsRendererFramework
//
//  Schema for section-based layouts with heterogeneous section types.
//

import Foundation

// MARK: - Section Layout

extension Document {
    /// A layout containing multiple sections, each with its own layout type
    public struct SectionLayout: Codable {
        public let id: String?
        public let sectionSpacing: CGFloat?
        public let sections: [SectionDefinition]

        public init(
            id: String? = nil,
            sectionSpacing: CGFloat? = nil,
            sections: [SectionDefinition]
        ) {
            self.id = id
            self.sectionSpacing = sectionSpacing
            self.sections = sections
        }
    }
}

// MARK: - Section Definition

extension Document {
    /// Definition of a single section within a SectionLayout
    public struct SectionDefinition: Codable {
        public let id: String?
        public let layout: SectionLayoutConfig
        public let header: LayoutNode?
        public let footer: LayoutNode?
        public let stickyHeader: Bool?

        // Static children
        public let children: [LayoutNode]?

        // Data-driven children
        public let dataSource: String?      // State path to array
        public let itemTemplate: LayoutNode? // Template for each item

        public init(
            id: String? = nil,
            layout: SectionLayoutConfig,
            header: LayoutNode? = nil,
            footer: LayoutNode? = nil,
            stickyHeader: Bool? = nil,
            children: [LayoutNode]? = nil,
            dataSource: String? = nil,
            itemTemplate: LayoutNode? = nil
        ) {
            self.id = id
            self.layout = layout
            self.header = header
            self.footer = footer
            self.stickyHeader = stickyHeader
            self.children = children
            self.dataSource = dataSource
            self.itemTemplate = itemTemplate
        }
    }
}

// MARK: - Section Layout Config

extension Document {
    /// Layout configuration for a section, combining type and settings
    ///
    /// JSON example:
    /// ```json
    /// {
    ///   "type": "horizontal",
    ///   "itemSpacing": 12,
    ///   "itemDimensions": {
    ///     "width": { "fractional": 0.8 },
    ///     "aspectRatio": 1.2
    ///   },
    ///   "snapBehavior": "viewAligned"
    /// }
    /// ```
    public struct SectionLayoutConfig: Codable {
        // Layout type
        public let type: SectionType

        // Common settings
        public let alignment: SectionAlignment?
        public let itemSpacing: CGFloat?
        public let lineSpacing: CGFloat?
        public let contentInsets: Padding?

        // Item dimensions (for horizontal/grid sections)
        public let itemDimensions: ItemDimensions?

        // Horizontal section
        public let showsIndicators: Bool?
        public let isPagingEnabled: Bool?
        public let snapBehavior: SnapBehavior?

        // Grid section
        public let columns: ColumnConfig?

        // List section
        public let showsDividers: Bool?

        public init(
            type: SectionType,
            alignment: SectionAlignment? = nil,
            itemSpacing: CGFloat? = nil,
            lineSpacing: CGFloat? = nil,
            contentInsets: Padding? = nil,
            itemDimensions: ItemDimensions? = nil,
            showsIndicators: Bool? = nil,
            isPagingEnabled: Bool? = nil,
            snapBehavior: SnapBehavior? = nil,
            columns: ColumnConfig? = nil,
            showsDividers: Bool? = nil
        ) {
            self.type = type
            self.alignment = alignment
            self.itemSpacing = itemSpacing
            self.lineSpacing = lineSpacing
            self.contentInsets = contentInsets
            self.itemDimensions = itemDimensions
            self.showsIndicators = showsIndicators
            self.isPagingEnabled = isPagingEnabled
            self.snapBehavior = snapBehavior
            self.columns = columns
            self.showsDividers = showsDividers
        }
    }
}

// MARK: - Section Alignment

extension Document {
    /// Horizontal alignment option for section content
    public enum SectionAlignment: String, Codable {
        case leading
        case center
        case trailing
    }
}

// MARK: - Section Type

extension Document {
    /// The layout type for a section
    public enum SectionType: String, Codable {
        case horizontal  // Horizontally scrolling row
        case list        // Vertical list (table-like)
        case grid        // Grid layout
        case flow        // Flow/wrapping layout
    }
}

// MARK: - Column Config

extension Document {
    /// Configuration for grid columns - either fixed count or adaptive
    public enum ColumnConfig: Codable, Equatable {
        case fixed(Int)
        case adaptive(minWidth: CGFloat)

        enum CodingKeys: String, CodingKey {
            case adaptive
            case minWidth
        }

        public init(from decoder: Decoder) throws {
            // Try decoding as a simple integer first (fixed columns)
            if let container = try? decoder.singleValueContainer(),
               let count = try? container.decode(Int.self) {
                self = .fixed(count)
                return
            }

            // Try decoding as adaptive config
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let adaptiveContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .adaptive) {
                let minWidth = try adaptiveContainer.decode(CGFloat.self, forKey: .minWidth)
                self = .adaptive(minWidth: minWidth)
                return
            }

            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int or { adaptive: { minWidth: CGFloat } }"
                )
            )
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .fixed(let count):
                var container = encoder.singleValueContainer()
                try container.encode(count)
            case .adaptive(let minWidth):
                var container = encoder.container(keyedBy: CodingKeys.self)
                var adaptiveContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .adaptive)
                try adaptiveContainer.encode(minWidth, forKey: .minWidth)
            }
        }
    }
}

// MARK: - Item Dimensions

extension Document {
    /// Dimensions for section items
    ///
    /// JSON examples:
    /// ```json
    /// { "width": { "fractional": 0.8 }, "aspectRatio": 1.2 }
    /// { "width": { "absolute": 280 }, "height": { "absolute": 200 } }
    /// { "width": 280, "height": 200 }
    /// ```
    public struct ItemDimensions: Codable {
        public let width: DimensionValue?
        public let height: DimensionValue?
        public let aspectRatio: CGFloat?

        public init(
            width: DimensionValue? = nil,
            height: DimensionValue? = nil,
            aspectRatio: CGFloat? = nil
        ) {
            self.width = width
            self.height = height
            self.aspectRatio = aspectRatio
        }
    }
}

// MARK: - Dimension Value

extension Document {
    /// A dimension value that can be absolute or fractional
    ///
    /// JSON examples:
    /// ```json
    /// { "fractional": 0.8 }  // 80% of container
    /// { "absolute": 200 }    // Fixed 200pt
    /// 200                    // Shorthand for absolute
    /// ```
    public enum DimensionValue: Codable, Equatable {
        case absolute(CGFloat)
        case fractional(CGFloat)

        enum CodingKeys: String, CodingKey {
            case absolute
            case fractional
        }

        public init(from decoder: Decoder) throws {
            // Try decoding as a simple number first (absolute shorthand)
            if let container = try? decoder.singleValueContainer(),
               let value = try? container.decode(CGFloat.self) {
                self = .absolute(value)
                return
            }

            // Try decoding as object with explicit type
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let value = try container.decodeIfPresent(CGFloat.self, forKey: .fractional) {
                self = .fractional(value)
                return
            }

            if let value = try container.decodeIfPresent(CGFloat.self, forKey: .absolute) {
                self = .absolute(value)
                return
            }

            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected number or { fractional: CGFloat } or { absolute: CGFloat }"
                )
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .absolute(let value):
                try container.encode(value, forKey: .absolute)
            case .fractional(let value):
                try container.encode(value, forKey: .fractional)
            }
        }
    }
}

// MARK: - Snap Behavior

extension Document {
    /// Scroll snap behavior for horizontal sections
    public enum SnapBehavior: String, Codable {
        /// No snapping, free scroll
        case none
        /// Snap to item edges
        case viewAligned
        /// One page at a time
        case paging
    }
}
