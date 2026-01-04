//
//  RenderTree.swift
//  CladsRendererFramework
//
//  Intermediate Representation (IR) for rendering.
//  This is the resolved, ready-to-render tree structure.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Render Tree

/// The root of the resolved render tree
/// All styles resolved, data bound, references validated
public struct RenderTree {
    /// The root node containing all children
    public let root: RootNode

    /// Reference to state store for dynamic updates
    public let stateStore: StateStore

    /// Action definitions for execution
    public let actions: [String: ActionDefinition]

    public init(root: RootNode, stateStore: StateStore, actions: [String: ActionDefinition]) {
        self.root = root
        self.stateStore = stateStore
        self.actions = actions
    }
}

// MARK: - Color Scheme

/// The color scheme for rendering (light/dark mode)
public enum RenderColorScheme {
    case light
    case dark
    case system  // Use system setting
}

// MARK: - Root Node

/// The resolved root container
public struct RootNode {
    public let backgroundColor: Color?
    public let edgeInsets: IR.EdgeInsets?
    public let colorScheme: RenderColorScheme
    public let style: IR.Style
    public let actions: RootActions
    public let children: [RenderNode]

    public init(
        backgroundColor: Color? = nil,
        edgeInsets: IR.EdgeInsets? = nil,
        colorScheme: RenderColorScheme = .system,
        style: IR.Style = IR.Style(),
        actions: RootActions = RootActions(),
        children: [RenderNode] = []
    ) {
        self.backgroundColor = backgroundColor
        self.edgeInsets = edgeInsets
        self.colorScheme = colorScheme
        self.style = style
        self.actions = actions
        self.children = children
    }
}

// MARK: - Render Node Kind

/// Type-safe render node kind identifier.
///
/// Uses struct with static constants for compile-time safety while remaining extensible.
/// External modules can add new render node kinds without modifying core code.
///
/// Built-in kinds are accessed via static properties:
/// ```swift
/// RenderNodeKind.text
/// RenderNodeKind.button
/// ```
///
/// External modules can extend with new kinds:
/// ```swift
/// extension RenderNodeKind {
///     public static let chart = RenderNodeKind(rawValue: "chart")
/// }
/// ```
public struct RenderNodeKind: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Built-in Render Node Kinds

extension RenderNodeKind {
    public static let container = RenderNodeKind(rawValue: "container")
    public static let sectionLayout = RenderNodeKind(rawValue: "sectionLayout")
    public static let text = RenderNodeKind(rawValue: "text")
    public static let button = RenderNodeKind(rawValue: "button")
    public static let textField = RenderNodeKind(rawValue: "textField")
    public static let toggle = RenderNodeKind(rawValue: "toggle")
    public static let slider = RenderNodeKind(rawValue: "slider")
    public static let image = RenderNodeKind(rawValue: "image")
    public static let gradient = RenderNodeKind(rawValue: "gradient")
    public static let spacer = RenderNodeKind(rawValue: "spacer")
    public static let custom = RenderNodeKind(rawValue: "custom")
}

// MARK: - Custom Render Node Protocol

/// Protocol for custom render nodes defined by external modules.
///
/// Implement this protocol to create custom component render nodes.
///
/// Example:
/// ```swift
/// struct ChartNode: CustomRenderNode {
///     static let kind = RenderNodeKind(rawValue: "chart")
///
///     let dataPoints: [Double]
///     let chartType: String
///     let style: IR.Style
/// }
/// ```
public protocol CustomRenderNode: Sendable {
    /// The kind identifier for this custom node
    static var kind: RenderNodeKind { get }
}

// MARK: - Render Node

/// A node in the render tree - either a container or a leaf component
public enum RenderNode {
    case container(ContainerNode)
    case sectionLayout(SectionLayoutNode)
    case text(TextNode)
    case button(ButtonNode)
    case textField(TextFieldNode)
    case toggle(ToggleNode)
    case slider(SliderNode)
    case image(ImageNode)
    case gradient(GradientNode)
    case spacer
    /// Custom render node for extensible components
    case custom(kind: RenderNodeKind, node: any CustomRenderNode)

    /// The kind of this render node
    public var kind: RenderNodeKind {
        switch self {
        case .container: return .container
        case .sectionLayout: return .sectionLayout
        case .text: return .text
        case .button: return .button
        case .textField: return .textField
        case .toggle: return .toggle
        case .slider: return .slider
        case .image: return .image
        case .gradient: return .gradient
        case .spacer: return .spacer
        case .custom(let kind, _): return kind
        }
    }
}

// MARK: - Container Node

/// A layout container (VStack, HStack, ZStack)
public struct ContainerNode {
    /// Layout type for containers
    public enum LayoutType {
        case vstack
        case hstack
        case zstack
    }

    public let id: String?
    public let layoutType: LayoutType
    public let alignment: SwiftUI.Alignment
    public let spacing: CGFloat
    public let padding: NSDirectionalEdgeInsets
    public let style: IR.Style
    public let children: [RenderNode]

    public init(
        id: String? = nil,
        layoutType: LayoutType = .vstack,
        alignment: SwiftUI.Alignment = .center,
        spacing: CGFloat = 0,
        padding: NSDirectionalEdgeInsets = .zero,
        style: IR.Style = IR.Style(),
        children: [RenderNode] = []
    ) {
        self.id = id
        self.layoutType = layoutType
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.style = style
        self.children = children
    }
}


// MARK: - Section Layout Node

/// A section-based layout container for heterogeneous sections
public struct SectionLayoutNode {
    public let id: String?
    public let sectionSpacing: CGFloat
    public let sections: [IR.Section]

    public init(
        id: String? = nil,
        sectionSpacing: CGFloat = 0,
        sections: [IR.Section] = []
    ) {
        self.id = id
        self.sectionSpacing = sectionSpacing
        self.sections = sections
    }
}

// MARK: - NSDirectionalEdgeInsets Extension

extension NSDirectionalEdgeInsets {
    public var isEmpty: Bool {
        top == 0 && bottom == 0 && leading == 0 && trailing == 0
    }
}

// MARK: - Text Node

/// A text/label component
public struct TextNode {
    public let id: String?
    public let content: String
    public let style: IR.Style
    public let padding: NSDirectionalEdgeInsets
    /// If set, the content should be read dynamically from StateStore at this path
    public let bindingPath: String?
    /// If set, this template should be interpolated with StateStore values (e.g., "Hello ${name}")
    public let bindingTemplate: String?

    /// Whether this text node has dynamic content that should be observed
    public var isDynamic: Bool {
        bindingPath != nil || bindingTemplate != nil
    }

    public init(
        id: String? = nil,
        content: String,
        style: IR.Style = IR.Style(),
        padding: NSDirectionalEdgeInsets = .zero,
        bindingPath: String? = nil,
        bindingTemplate: String? = nil
    ) {
        self.id = id
        self.content = content
        self.style = style
        self.padding = padding
        self.bindingPath = bindingPath
        self.bindingTemplate = bindingTemplate
    }
}

// MARK: - Button Node

/// Resolved styles for different button states
public struct ButtonStyles {
    public let normal: IR.Style
    public let selected: IR.Style?
    public let disabled: IR.Style?

    public init(
        normal: IR.Style = IR.Style(),
        selected: IR.Style? = nil,
        disabled: IR.Style? = nil
    ) {
        self.normal = normal
        self.selected = selected
        self.disabled = disabled
    }

    /// Get the appropriate style for the current state
    public func style(isSelected: Bool, isDisabled: Bool = false) -> IR.Style {
        if isDisabled, let disabled = disabled {
            return disabled
        }
        if isSelected, let selected = selected {
            return selected
        }
        return normal
    }
}

/// A button component
public struct ButtonNode {
    public let id: String?
    public let label: String
    public let styles: ButtonStyles
    public let isSelectedBinding: String?
    public let fillWidth: Bool
    public let onTap: Document.Component.ActionBinding?

    /// Convenience accessor for backward compatibility
    public var style: IR.Style { styles.normal }

    public init(
        id: String? = nil,
        label: String,
        styles: ButtonStyles = ButtonStyles(),
        isSelectedBinding: String? = nil,
        fillWidth: Bool = false,
        onTap: Document.Component.ActionBinding? = nil
    ) {
        self.id = id
        self.label = label
        self.styles = styles
        self.isSelectedBinding = isSelectedBinding
        self.fillWidth = fillWidth
        self.onTap = onTap
    }
}

// MARK: - TextField Node

/// A text input component
public struct TextFieldNode {
    public let id: String?
    public let placeholder: String
    public let style: IR.Style
    public let bindingPath: String?  // State path to bind to

    public init(
        id: String? = nil,
        placeholder: String = "",
        style: IR.Style = IR.Style(),
        bindingPath: String? = nil
    ) {
        self.id = id
        self.placeholder = placeholder
        self.style = style
        self.bindingPath = bindingPath
    }
}

// MARK: - Toggle Node

/// A toggle/switch component
public struct ToggleNode {
    public let id: String?
    public let bindingPath: String?  // State path to bind to
    public let style: IR.Style

    public init(
        id: String? = nil,
        bindingPath: String? = nil,
        style: IR.Style = IR.Style()
    ) {
        self.id = id
        self.bindingPath = bindingPath
        self.style = style
    }
}

// MARK: - Slider Node

/// A slider component
public struct SliderNode {
    public let id: String?
    public let bindingPath: String?  // State path to bind to (Double value 0.0-1.0)
    public let minValue: Double
    public let maxValue: Double
    public let style: IR.Style

    public init(
        id: String? = nil,
        bindingPath: String? = nil,
        minValue: Double = 0.0,
        maxValue: Double = 1.0,
        style: IR.Style = IR.Style()
    ) {
        self.id = id
        self.bindingPath = bindingPath
        self.minValue = minValue
        self.maxValue = maxValue
        self.style = style
    }
}

// MARK: - Image Node

/// An image component
public struct ImageNode {
    /// Image source type
    public enum Source {
        case system(name: String)
        case asset(name: String)
        case url(URL)
    }

    public let id: String?
    public let source: Source
    public let style: IR.Style

    public init(id: String? = nil, source: Source, style: IR.Style = IR.Style()) {
        self.id = id
        self.source = source
        self.style = style
    }
}

// MARK: - Gradient Node

/// A gradient overlay component
public struct GradientNode {
    /// Gradient type
    public enum GradientType {
        case linear
        case radial
    }

    public let id: String?
    public let gradientType: GradientType
    public let colors: [ColorStop]
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint
    public let style: IR.Style

    public init(
        id: String? = nil,
        gradientType: GradientType = .linear,
        colors: [ColorStop],
        startPoint: UnitPoint = .bottom,
        endPoint: UnitPoint = .top,
        style: IR.Style = IR.Style()
    ) {
        self.id = id
        self.gradientType = gradientType
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.style = style
    }
}

extension GradientNode {
    /// A color stop in a gradient
    public struct ColorStop {
        public let color: GradientColor
        public let location: CGFloat  // 0.0 to 1.0

        public init(color: GradientColor, location: CGFloat) {
            self.color = color
            self.location = location
        }
    }
}

/// Color for gradient - can be static or adapt to color scheme
public enum GradientColor {
    case fixed(Color)
    case adaptive(light: Color, dark: Color)

    public func resolved(for scheme: RenderColorScheme, systemScheme: ColorScheme) -> Color {
        switch self {
        case .fixed(let color):
            return color
        case .adaptive(let light, let dark):
            let effectiveScheme: ColorScheme
            switch scheme {
            case .light: effectiveScheme = .light
            case .dark: effectiveScheme = .dark
            case .system: effectiveScheme = systemScheme
            }
            return effectiveScheme == .dark ? dark : light
        }
    }
}


// MARK: - Action Definition

/// A resolved action ready for execution.
///
/// This is the IR representation of an action, used during execution.
/// Codable for serialization/debugging purposes.
public enum ActionDefinition: Codable {
    case dismiss
    case setState(path: String, value: StateSetValue)
    case toggleState(path: String)
    case showAlert(config: AlertActionConfig)
    case sequence(steps: [ActionDefinition])
    case navigate(destination: String, presentation: Document.NavigationPresentation)
    case custom(type: String, parameters: [String: Document.StateValue])

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, path, value, config, steps, destination, presentation, parameters
    }

    private enum ActionType: String, Codable {
        case dismiss, setState, toggleState, showAlert, sequence, navigate, custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
        case .dismiss:
            self = .dismiss
        case .setState:
            let path = try container.decode(String.self, forKey: .path)
            let value = try container.decode(StateSetValue.self, forKey: .value)
            self = .setState(path: path, value: value)
        case .toggleState:
            let path = try container.decode(String.self, forKey: .path)
            self = .toggleState(path: path)
        case .showAlert:
            let config = try container.decode(AlertActionConfig.self, forKey: .config)
            self = .showAlert(config: config)
        case .sequence:
            let steps = try container.decode([ActionDefinition].self, forKey: .steps)
            self = .sequence(steps: steps)
        case .navigate:
            let destination = try container.decode(String.self, forKey: .destination)
            let presentation = try container.decode(Document.NavigationPresentation.self, forKey: .presentation)
            self = .navigate(destination: destination, presentation: presentation)
        case .custom:
            let customType = try container.decode(String.self, forKey: .type)
            let parameters = try container.decodeIfPresent([String: Document.StateValue].self, forKey: .parameters) ?? [:]
            self = .custom(type: customType, parameters: parameters)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .dismiss:
            try container.encode(ActionType.dismiss, forKey: .type)
        case .setState(let path, let value):
            try container.encode(ActionType.setState, forKey: .type)
            try container.encode(path, forKey: .path)
            try container.encode(value, forKey: .value)
        case .toggleState(let path):
            try container.encode(ActionType.toggleState, forKey: .type)
            try container.encode(path, forKey: .path)
        case .showAlert(let config):
            try container.encode(ActionType.showAlert, forKey: .type)
            try container.encode(config, forKey: .config)
        case .sequence(let steps):
            try container.encode(ActionType.sequence, forKey: .type)
            try container.encode(steps, forKey: .steps)
        case .navigate(let destination, let presentation):
            try container.encode(ActionType.navigate, forKey: .type)
            try container.encode(destination, forKey: .destination)
            try container.encode(presentation, forKey: .presentation)
        case .custom(let customType, let parameters):
            try container.encode(customType, forKey: .type)
            try container.encode(parameters, forKey: .parameters)
        }
    }
}

/// Value to set in state.
///
/// Uses `Document.StateValue` for type-safe, Codable storage.
public enum StateSetValue: Codable {
    case literal(Document.StateValue)
    case expression(String)

    private enum CodingKeys: String, CodingKey {
        case type, value, expression
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        if type == "expression" {
            let expr = try container.decode(String.self, forKey: .expression)
            self = .expression(expr)
        } else {
            let value = try container.decode(Document.StateValue.self, forKey: .value)
            self = .literal(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .literal(let value):
            try container.encode("literal", forKey: .type)
            try container.encode(value, forKey: .value)
        case .expression(let expr):
            try container.encode("expression", forKey: .type)
            try container.encode(expr, forKey: .expression)
        }
    }

    /// Convert to Any for runtime use
    public func toAny() -> Any {
        switch self {
        case .literal(let stateValue):
            return StateValueConverter.unwrap(stateValue)
        case .expression(let expr):
            return expr
        }
    }
}

/// Alert action configuration
public struct AlertActionConfig: Codable {
    public let title: String
    public let message: AlertMessage?
    public let buttons: [AlertButtonConfig]

    public init(title: String, message: AlertMessage? = nil, buttons: [AlertButtonConfig] = []) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }
}

/// Alert message - static or dynamic
public enum AlertMessage: Codable {
    case `static`(String)
    case template(String)  // Contains ${variable} placeholders

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)

        if type == "template" {
            self = .template(value)
        } else {
            self = .static(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .static(let value):
            try container.encode("static", forKey: .type)
            try container.encode(value, forKey: .value)
        case .template(let value):
            try container.encode("template", forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

/// Alert button configuration
public struct AlertButtonConfig: Codable {
    public let label: String
    public let style: Document.AlertButtonStyle
    public let action: String?  // Action ID to execute

    public init(label: String, style: Document.AlertButtonStyle = .default, action: String? = nil) {
        self.label = label
        self.style = style
        self.action = action
    }
}
