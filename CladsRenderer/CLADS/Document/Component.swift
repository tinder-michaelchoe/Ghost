//
//  Component.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Component

// MARK: - Component Kind

extension Document {
    /// Type-safe component kind identifier.
    ///
    /// Uses struct with static constants for compile-time safety while remaining extensible.
    /// External modules can add new component kinds without modifying core code.
    ///
    /// Built-in kinds are accessed via static properties:
    /// ```swift
    /// ComponentKind.label
    /// ComponentKind.button
    /// ```
    ///
    /// External modules can extend with new kinds:
    /// ```swift
    /// extension Document.ComponentKind {
    ///     public static let chart = ComponentKind(rawValue: "chart")
    /// }
    /// ```
    ///
    /// When adding a new component type:
    /// 1. Add a static constant here (or in an extension for external types)
    /// 2. Create a corresponding `ComponentResolving` implementation
    /// 3. Register it with `ComponentResolverRegistry`
    public struct ComponentKind: Hashable, Codable, Sendable, RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Built-in Component Kinds

extension Document.ComponentKind {
    /// Text label component
    public static let label = Document.ComponentKind(rawValue: "label")

    /// Tappable button component
    public static let button = Document.ComponentKind(rawValue: "button")

    /// Text input field component
    public static let textfield = Document.ComponentKind(rawValue: "textfield")

    /// Image component (SF Symbols or URL)
    public static let image = Document.ComponentKind(rawValue: "image")

    /// Gradient background component
    public static let gradient = Document.ComponentKind(rawValue: "gradient")

    /// Boolean toggle switch component
    public static let toggle = Document.ComponentKind(rawValue: "toggle")

    /// Value slider component
    public static let slider = Document.ComponentKind(rawValue: "slider")
}

// MARK: - Component

extension Document {
    /// A UI component (label, button, textfield, etc.)
    public struct Component: Codable {

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

        public let type: ComponentKind
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

        // Slider-specific properties
        public let minValue: Double?
        public let maxValue: Double?

        // Image-specific properties
        public let image: ImageSource?

        // Gradient-specific properties
        public let gradientColors: [GradientColorConfig]?
        public let gradientStart: String?  // "top", "bottom", "leading", etc.
        public let gradientEnd: String?

        /// Additional properties for custom/extensible components.
        /// Captures any JSON keys not defined in the standard properties.
        public let additionalProperties: [String: AnyCodableValue]?

        public init(
            type: ComponentKind,
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
            minValue: Double? = nil,
            maxValue: Double? = nil,
            image: ImageSource? = nil,
            gradientColors: [GradientColorConfig]? = nil,
            gradientStart: String? = nil,
            gradientEnd: String? = nil,
            additionalProperties: [String: AnyCodableValue]? = nil
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
            self.minValue = minValue
            self.maxValue = maxValue
            self.image = image
            self.gradientColors = gradientColors
            self.gradientStart = gradientStart
            self.gradientEnd = gradientEnd
            self.additionalProperties = additionalProperties
        }

        // MARK: - Custom Decoding

        /// Known coding keys for standard properties
        private enum CodingKeys: String, CodingKey, CaseIterable {
            case type, id, styleId, styles, padding, isSelectedBinding
            case dataSourceId, text, placeholder, bind, localBind
            case fillWidth, actions, data, state
            case minValue, maxValue, image
            case gradientColors, gradientStart, gradientEnd
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Decode standard properties
            type = try container.decode(ComponentKind.self, forKey: .type)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            styleId = try container.decodeIfPresent(String.self, forKey: .styleId)
            styles = try container.decodeIfPresent(ComponentStyles.self, forKey: .styles)
            padding = try container.decodeIfPresent(Padding.self, forKey: .padding)
            isSelectedBinding = try container.decodeIfPresent(String.self, forKey: .isSelectedBinding)
            dataSourceId = try container.decodeIfPresent(String.self, forKey: .dataSourceId)
            text = try container.decodeIfPresent(String.self, forKey: .text)
            placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
            bind = try container.decodeIfPresent(String.self, forKey: .bind)
            localBind = try container.decodeIfPresent(String.self, forKey: .localBind)
            fillWidth = try container.decodeIfPresent(Bool.self, forKey: .fillWidth)
            actions = try container.decodeIfPresent(Actions.self, forKey: .actions)
            data = try container.decodeIfPresent(DataReference.self, forKey: .data)
            state = try container.decodeIfPresent(LocalStateDeclaration.self, forKey: .state)
            minValue = try container.decodeIfPresent(Double.self, forKey: .minValue)
            maxValue = try container.decodeIfPresent(Double.self, forKey: .maxValue)
            image = try container.decodeIfPresent(ImageSource.self, forKey: .image)
            gradientColors = try container.decodeIfPresent([GradientColorConfig].self, forKey: .gradientColors)
            gradientStart = try container.decodeIfPresent(String.self, forKey: .gradientStart)
            gradientEnd = try container.decodeIfPresent(String.self, forKey: .gradientEnd)

            // Capture additional properties using dynamic keys
            let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
            let knownKeys = Set(CodingKeys.allCases.map { $0.rawValue })
            var additional: [String: AnyCodableValue] = [:]

            for key in dynamicContainer.allKeys {
                if !knownKeys.contains(key.stringValue) {
                    if let value = try? dynamicContainer.decode(AnyCodableValue.self, forKey: key) {
                        additional[key.stringValue] = value
                    }
                }
            }

            additionalProperties = additional.isEmpty ? nil : additional
        }
    }
}

// MARK: - Dynamic Coding Key

/// Dynamic coding key for capturing unknown JSON keys
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
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
