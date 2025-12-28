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
    public let edgeInsets: Document.EdgeInsets?
    public let colorScheme: RenderColorScheme
    public let style: IR.Style
    public let children: [RenderNode]

    public init(
        backgroundColor: Color? = nil,
        edgeInsets: Document.EdgeInsets? = nil,
        colorScheme: RenderColorScheme = .system,
        style: IR.Style = IR.Style(),
        children: [RenderNode] = []
    ) {
        self.backgroundColor = backgroundColor
        self.edgeInsets = edgeInsets
        self.colorScheme = colorScheme
        self.style = style
        self.children = children
    }
}

// MARK: - Render Node

/// A node in the render tree - either a container or a leaf component
public enum RenderNode {
    case container(ContainerNode)
    case sectionLayout(SectionLayoutNode)
    case text(TextNode)
    case button(ButtonNode)
    case textField(TextFieldNode)
    case image(ImageNode)
    case gradient(GradientNode)
    case spacer

    /// Identifies the type of render node (for renderer dispatch)
    public enum Kind: CaseIterable {
        case container
        case sectionLayout
        case text
        case button
        case textField
        case image
        case gradient
        case spacer
    }

    /// The kind of this render node
    public var kind: Kind {
        switch self {
        case .container: return .container
        case .sectionLayout: return .sectionLayout
        case .text: return .text
        case .button: return .button
        case .textField: return .textField
        case .image: return .image
        case .gradient: return .gradient
        case .spacer: return .spacer
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

    public init(id: String? = nil, content: String, style: IR.Style = IR.Style()) {
        self.id = id
        self.content = content
        self.style = style
    }
}

// MARK: - Button Node

/// A button component
public struct ButtonNode {
    public let id: String?
    public let label: String
    public let style: IR.Style
    public let fillWidth: Bool
    public let onTap: Document.Component.ActionBinding?

    public init(
        id: String? = nil,
        label: String,
        style: IR.Style = IR.Style(),
        fillWidth: Bool = false,
        onTap: Document.Component.ActionBinding? = nil
    ) {
        self.id = id
        self.label = label
        self.style = style
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
    case showAlert(config: AlertActionConfig)
    case sequence(steps: [ActionDefinition])
    case navigate(destination: String, presentation: Document.NavigationPresentation)
    case custom(type: String, parameters: [String: Document.StateValue])

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, path, value, config, steps, destination, presentation, parameters
    }

    private enum ActionType: String, Codable {
        case dismiss, setState, showAlert, sequence, navigate, custom
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
