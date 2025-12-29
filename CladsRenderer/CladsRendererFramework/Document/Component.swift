//
//  Component.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Component

extension Document {
    /// A UI component (label, button, textfield, etc.)
    public struct Component: Codable {

        // MARK: - Nested Types

        /// Component types supported by the renderer.
        ///
        /// Each case's raw value corresponds exactly to the `"type"` field in JSON:
        /// ```json
        /// { "type": "label", ... }
        /// { "type": "button", ... }
        /// ```
        ///
        /// When adding a new component type:
        /// 1. Add a case here with a raw value matching the JSON `type` string
        /// 2. Create a corresponding `ComponentResolving` implementation
        /// 3. Register it in `ComponentResolverRegistry.default`
        public enum Kind: String, Codable {
            case label
            case button
            case textfield
            case image
            case gradient
        }

        /// An action binding - either an inline action or a reference to a document-level action.
        ///
        /// JSON examples:
        /// ```json
        /// "myActionId"                           // Reference to document action
        /// { "type": "dismiss" }                  // Inline dismiss action
        /// { "type": "setState", "path": "x" }    // Inline setState action
        /// ```
        public enum ActionBinding: Codable {
            case reference(String)
            case inline(Action)

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()

                // Try as string reference first
                if let ref = try? container.decode(String.self) {
                    self = .reference(ref)
                    return
                }

                // Otherwise decode as inline Action
                self = .inline(try Action(from: decoder))
            }

            public func encode(to encoder: Encoder) throws {
                switch self {
                case .reference(let id):
                    var container = encoder.singleValueContainer()
                    try container.encode(id)
                case .inline(let action):
                    try action.encode(to: encoder)
                }
            }
        }

        /// Actions that can be bound to component events.
        ///
        /// JSON example:
        /// ```json
        /// {
        ///   "onTap": "submitForm",
        ///   "onValueChanged": { "type": "setState", "path": "text", "value": { "$expr": "value" } }
        /// }
        /// ```
        public struct Actions: Codable {
            public let onTap: ActionBinding?
            public let onValueChanged: ActionBinding?

            public init(onTap: ActionBinding? = nil, onValueChanged: ActionBinding? = nil) {
                self.onTap = onTap
                self.onValueChanged = onValueChanged
            }
        }

        /// State-based styles for components (buttons, etc.)
        ///
        /// JSON example:
        /// ```json
        /// {
        ///   "normal": "pillButton",
        ///   "selected": "pillButtonSelected",
        ///   "disabled": "pillButtonDisabled"
        /// }
        /// ```
        public struct ComponentStyles: Codable {
            public let normal: String?
            public let selected: String?
            public let disabled: String?

            public init(normal: String? = nil, selected: String? = nil, disabled: String? = nil) {
                self.normal = normal
                self.selected = selected
                self.disabled = disabled
            }
        }

        // MARK: - Properties

        public let type: Kind
        public let id: String?
        public let styleId: String?
        public let styles: ComponentStyles?
        public let padding: Padding?
        public let isSelectedBinding: String?
        public let dataSourceId: String?
        public let text: String?
        public let placeholder: String?
        public let bind: String?          // Bind to global state
        public let localBind: String?     // Bind to local state (without "local." prefix)
        public let fillWidth: Bool?
        public let actions: Actions?
        public let data: DataReference?

        /// Local state declaration for this component
        public let state: LocalStateDeclaration?

        // Image-specific properties
        public let image: ImageSource?

        // Gradient-specific properties
        public let gradientColors: [GradientColorConfig]?
        public let gradientStart: String?  // "top", "bottom", "leading", etc.
        public let gradientEnd: String?

        public init(
            type: Kind,
            id: String? = nil,
            styleId: String? = nil,
            styles: ComponentStyles? = nil,
            padding: Padding? = nil,
            isSelectedBinding: String? = nil,
            dataSourceId: String? = nil,
            text: String? = nil,
            placeholder: String? = nil,
            bind: String? = nil,
            localBind: String? = nil,
            fillWidth: Bool? = nil,
            actions: Actions? = nil,
            data: DataReference? = nil,
            state: LocalStateDeclaration? = nil,
            image: ImageSource? = nil,
            gradientColors: [GradientColorConfig]? = nil,
            gradientStart: String? = nil,
            gradientEnd: String? = nil
        ) {
            self.type = type
            self.id = id
            self.styleId = styleId
            self.styles = styles
            self.padding = padding
            self.isSelectedBinding = isSelectedBinding
            self.dataSourceId = dataSourceId
            self.text = text
            self.placeholder = placeholder
            self.bind = bind
            self.localBind = localBind
            self.fillWidth = fillWidth
            self.actions = actions
            self.data = data
            self.state = state
            self.image = image
            self.gradientColors = gradientColors
            self.gradientStart = gradientStart
            self.gradientEnd = gradientEnd
        }
    }
}

// MARK: - Gradient Color Config

extension Document {
    /// Gradient color configuration in JSON
    public struct GradientColorConfig: Codable {
        public let color: String?        // Hex color for fixed
        public let lightColor: String?   // Hex color for light mode (adaptive)
        public let darkColor: String?    // Hex color for dark mode (adaptive)
        public let location: CGFloat     // 0.0 to 1.0

        public init(color: String? = nil, lightColor: String? = nil, darkColor: String? = nil, location: CGFloat) {
            self.color = color
            self.lightColor = lightColor
            self.darkColor = darkColor
            self.location = location
        }
    }
}

// MARK: - Data Reference

extension Document {
    /// Reference to a data source or inline data
    public struct DataReference: Codable {
        public let type: DataReferenceType
        public let value: String?
        public let path: String?
        public let template: String?

        public init(type: DataReferenceType, value: String? = nil, path: String? = nil, template: String? = nil) {
            self.type = type
            self.value = value
            self.path = path
            self.template = template
        }
    }

    public enum DataReferenceType: String, Codable {
        case `static`
        case binding
        case localBinding  // References local state with "local." prefix
    }
}

// MARK: - Image Source

extension Document {
    /// Image source for image components.
    ///
    /// JSON examples:
    /// ```json
    /// { "system": "star.fill" }                 // SF Symbol
    /// { "url": "https://example.com/img.png" }  // Remote URL
    /// ```
    public struct ImageSource: Codable, Equatable {
        /// SF Symbol name (mutually exclusive with `url`)
        public let system: String?
        /// Remote image URL (mutually exclusive with `system`)
        public let url: String?

        public init(system: String? = nil, url: String? = nil) {
            self.system = system
            self.url = url
        }
    }
}
