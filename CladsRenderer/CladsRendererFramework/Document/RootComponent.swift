//
//  RootComponent.swift
//  CladsRendererFramework
//

import Foundation
import UIKit

// MARK: - Root Component

extension Document {
    /// The root container for all UI elements
    /// Sits at the top of the component tree and configures screen-level properties
    public struct RootComponent: Codable {
        /// Background color for the entire screen (hex string)
        public let backgroundColor: String?

        /// Edge insets configuration (safe area or absolute)
        public let edgeInsets: EdgeInsets?

        /// Default style ID applied to the root container
        public let styleId: String?

        /// Color scheme preference: "light", "dark", or "system" (default)
        public let colorScheme: String?

        /// Child nodes contained within the root
        public let children: [LayoutNode]

        public init(
            backgroundColor: String? = nil,
            edgeInsets: EdgeInsets? = nil,
            styleId: String? = nil,
            colorScheme: String? = nil,
            children: [LayoutNode] = []
        ) {
            self.backgroundColor = backgroundColor
            self.edgeInsets = edgeInsets
            self.styleId = styleId
            self.colorScheme = colorScheme
            self.children = children
        }
    }
}

// MARK: - Edge Insets

extension Document {
    /// Configuration for edge insets behavior (safe area or absolute)
    public struct EdgeInsets: Codable {
        public let top: EdgeInset?
        public let bottom: EdgeInset?
        public let leading: EdgeInset?
        public let trailing: EdgeInset?

        public init(
            top: EdgeInset? = nil,
            bottom: EdgeInset? = nil,
            leading: EdgeInset? = nil,
            trailing: EdgeInset? = nil
        ) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }

        /// Converts to NSDirectionalEdgeInsets for UIKit layout
        public var directionalInsets: NSDirectionalEdgeInsets {
            NSDirectionalEdgeInsets(
                top: top?.padding ?? 0,
                leading: leading?.padding ?? 0,
                bottom: bottom?.padding ?? 0,
                trailing: trailing?.padding ?? 0
            )
        }
    }
}

// MARK: - Edge Inset

extension Document {
    /// Configuration for a single edge's inset behavior
    public enum EdgeInset: Codable, Equatable {
        /// Align to the safe area edge with optional padding
        case safeArea(padding: CGFloat = 0)

        /// Align to the absolute screen edge with optional padding
        case absolute(padding: CGFloat = 0)

        /// Get the padding value for this edge inset
        public var padding: CGFloat {
            switch self {
            case .safeArea(let padding): return padding
            case .absolute(let padding): return padding
            }
        }

        /// Check if this is absolute mode
        public var isAbsolute: Bool {
            if case .absolute = self { return true }
            return false
        }

        // Custom decoding to support shorthand syntax
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            // Try decoding as a string first (shorthand: "absolute" or "safeArea")
            if let modeString = try? container.decode(String.self) {
                switch modeString.lowercased() {
                case "absolute":
                    self = .absolute()
                default:
                    self = .safeArea()
                }
                return
            }

            // Try decoding as a number (shorthand: padding value with safeArea mode)
            if let paddingValue = try? container.decode(CGFloat.self) {
                self = .safeArea(padding: paddingValue)
                return
            }

            // Full object syntax
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            let mode = try keyedContainer.decodeIfPresent(String.self, forKey: .mode) ?? "safeArea"
            let padding = try keyedContainer.decodeIfPresent(CGFloat.self, forKey: .padding) ?? 0

            switch mode.lowercased() {
            case "absolute":
                self = .absolute(padding: padding)
            default:
                self = .safeArea(padding: padding)
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .safeArea(let padding) where padding == 0:
                var container = encoder.singleValueContainer()
                try container.encode("safeArea")
            case .absolute(let padding) where padding == 0:
                var container = encoder.singleValueContainer()
                try container.encode("absolute")
            case .safeArea(let padding):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode("safeArea", forKey: .mode)
                try container.encode(padding, forKey: .padding)
            case .absolute(let padding):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode("absolute", forKey: .mode)
                try container.encode(padding, forKey: .padding)
            }
        }

        enum CodingKeys: String, CodingKey {
            case mode, padding
        }
    }
}
