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

        /// Lifecycle and other action bindings for the root
        public let actions: RootActions?

        /// Child nodes contained within the root
        public let children: [LayoutNode]

        public init(
            backgroundColor: String? = nil,
            edgeInsets: EdgeInsets? = nil,
            styleId: String? = nil,
            colorScheme: String? = nil,
            actions: RootActions? = nil,
            children: [LayoutNode] = []
        ) {
            self.backgroundColor = backgroundColor
            self.edgeInsets = edgeInsets
            self.styleId = styleId
            self.colorScheme = colorScheme
            self.actions = actions
            self.children = children
        }
    }
    
    /// Action bindings for the root component (lifecycle hooks)
    public struct RootActions: Codable {
        public let onAppear: Component.ActionBinding?
        public let onDisappear: Component.ActionBinding?

        public init(
            onAppear: Component.ActionBinding? = nil,
            onDisappear: Component.ActionBinding? = nil
        ) {
            self.onAppear = onAppear
            self.onDisappear = onDisappear
        }
    }
}

// MARK: - Edge Insets

extension Document {
    /// Positioning reference for edge insets
    public enum Positioning: String, Codable {
        /// Position relative to safe area boundaries (default)
        case safeArea
        /// Position relative to absolute screen edges (ignores safe area)
        case absolute
    }
}

extension Document {
    /// Configuration for a single edge inset
    public struct EdgeInset: Codable, Equatable {
        public let positioning: Positioning
        public let value: CGFloat

        public init(positioning: Positioning = .safeArea, value: CGFloat) {
            self.positioning = positioning
            self.value = value
        }

        // Support shorthand: just a number defaults to safeArea positioning
        public init(from decoder: Decoder) throws {
            // Try as single value (number) first - defaults to safeArea
            if let container = try? decoder.singleValueContainer(),
               let value = try? container.decode(CGFloat.self) {
                self.positioning = .safeArea
                self.value = value
                return
            }

            // Try as object with positioning and value
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.positioning = try container.decodeIfPresent(Positioning.self, forKey: .positioning) ?? .safeArea
            self.value = try container.decode(CGFloat.self, forKey: .value)
        }

        public func encode(to encoder: Encoder) throws {
            // Use shorthand for safeArea with value
            if positioning == .safeArea {
                var container = encoder.singleValueContainer()
                try container.encode(value)
            } else {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(positioning, forKey: .positioning)
                try container.encode(value, forKey: .value)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case positioning, value
        }
    }
}

extension Document {
    /// Configuration for edge insets on all four edges
    ///
    /// Example JSON:
    /// ```json
    /// {
    ///   "top": 16,                                    // 16pt from safe area (shorthand)
    ///   "bottom": { "positioning": "absolute", "value": 0 }  // At absolute bottom
    /// }
    /// ```
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
    }
}
