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
        public let layout: SectionType
        public let header: LayoutNode?
        public let footer: LayoutNode?
        public let stickyHeader: Bool?
        public let config: SectionConfig?

        // Static children
        public let children: [LayoutNode]?

        // Data-driven children
        public let dataSource: String?      // State path to array
        public let itemTemplate: LayoutNode? // Template for each item

        public init(
            id: String? = nil,
            layout: SectionType,
            header: LayoutNode? = nil,
            footer: LayoutNode? = nil,
            stickyHeader: Bool? = nil,
            config: SectionConfig? = nil,
            children: [LayoutNode]? = nil,
            dataSource: String? = nil,
            itemTemplate: LayoutNode? = nil
        ) {
            self.id = id
            self.layout = layout
            self.header = header
            self.footer = footer
            self.stickyHeader = stickyHeader
            self.config = config
            self.children = children
            self.dataSource = dataSource
            self.itemTemplate = itemTemplate
        }
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

// MARK: - Section Config

extension Document {
    /// Configuration options for a section
    public struct SectionConfig: Codable {
        // Common
        public let itemSpacing: CGFloat?
        public let lineSpacing: CGFloat?
        public let contentInsets: Padding?

        // Horizontal section
        public let showsIndicators: Bool?
        public let isPagingEnabled: Bool?

        // Grid section
        public let columns: ColumnConfig?

        // List section
        public let showsDividers: Bool?

        public init(
            itemSpacing: CGFloat? = nil,
            lineSpacing: CGFloat? = nil,
            contentInsets: Padding? = nil,
            showsIndicators: Bool? = nil,
            isPagingEnabled: Bool? = nil,
            columns: ColumnConfig? = nil,
            showsDividers: Bool? = nil
        ) {
            self.itemSpacing = itemSpacing
            self.lineSpacing = lineSpacing
            self.contentInsets = contentInsets
            self.showsIndicators = showsIndicators
            self.isPagingEnabled = isPagingEnabled
            self.columns = columns
            self.showsDividers = showsDividers
        }
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
