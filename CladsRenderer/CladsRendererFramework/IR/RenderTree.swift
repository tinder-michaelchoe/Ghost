//
//  RenderTree.swift
//  CladsRendererFramework
//
//  Intermediate Representation (IR) for rendering.
//  This is the resolved, ready-to-render tree structure.
//

import Foundation
import SwiftUI

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

// MARK: - Root Node

/// The resolved root container
public struct RootNode {
    public let backgroundColor: Color?
    public let edgeInsets: EdgeInsets?
    public let style: ResolvedStyle
    public let children: [RenderNode]

    public init(
        backgroundColor: Color? = nil,
        edgeInsets: EdgeInsets? = nil,
        style: ResolvedStyle = ResolvedStyle(),
        children: [RenderNode] = []
    ) {
        self.backgroundColor = backgroundColor
        self.edgeInsets = edgeInsets
        self.style = style
        self.children = children
    }
}

// MARK: - Render Node

/// A node in the render tree - either a container or a leaf component
public enum RenderNode {
    case container(ContainerNode)
    case text(TextNode)
    case button(ButtonNode)
    case textField(TextFieldNode)
    case image(ImageNode)
    case spacer
}

// MARK: - Container Node

/// A layout container (VStack, HStack, ZStack)
public struct ContainerNode {
    public let id: String?
    public let axis: Axis
    public let alignment: ContainerAlignment
    public let spacing: CGFloat
    public let padding: ResolvedPadding
    public let style: ResolvedStyle
    public let children: [RenderNode]

    public init(
        id: String? = nil,
        axis: Axis = .vertical,
        alignment: ContainerAlignment = .center,
        spacing: CGFloat = 0,
        padding: ResolvedPadding = ResolvedPadding(),
        style: ResolvedStyle = ResolvedStyle(),
        children: [RenderNode] = []
    ) {
        self.id = id
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.style = style
        self.children = children
    }
}

/// Container alignment options
public enum ContainerAlignment {
    case leading
    case center
    case trailing
    case top
    case bottom
}

/// Resolved padding values
public struct ResolvedPadding {
    public let top: CGFloat
    public let bottom: CGFloat
    public let leading: CGFloat
    public let trailing: CGFloat

    public init(top: CGFloat = 0, bottom: CGFloat = 0, leading: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
    }

    public var isEmpty: Bool {
        top == 0 && bottom == 0 && leading == 0 && trailing == 0
    }
}

// MARK: - Text Node

/// A text/label component
public struct TextNode {
    public let id: String?
    public let content: String
    public let style: ResolvedStyle

    public init(id: String? = nil, content: String, style: ResolvedStyle = ResolvedStyle()) {
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
    public let style: ResolvedStyle
    public let fillWidth: Bool
    public let onTap: String?  // Action ID to execute

    public init(
        id: String? = nil,
        label: String,
        style: ResolvedStyle = ResolvedStyle(),
        fillWidth: Bool = false,
        onTap: String? = nil
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
    public let style: ResolvedStyle
    public let bindingPath: String?  // State path to bind to

    public init(
        id: String? = nil,
        placeholder: String = "",
        style: ResolvedStyle = ResolvedStyle(),
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
    public let id: String?
    public let source: ImageSource
    public let style: ResolvedStyle

    public init(id: String? = nil, source: ImageSource, style: ResolvedStyle = ResolvedStyle()) {
        self.id = id
        self.source = source
        self.style = style
    }
}

/// Image source type
public enum ImageSource {
    case system(name: String)
    case asset(name: String)
    case url(URL)
}

// MARK: - Action Definition

/// A resolved action ready for execution
public enum ActionDefinition {
    case dismiss
    case setState(path: String, value: StateSetValue)
    case showAlert(config: AlertActionConfig)
    case sequence(steps: [ActionDefinition])
    case navigate(destination: String, presentation: NavigationPresentation)
    case custom(type: String, parameters: [String: Any])
}

/// Value to set in state
public enum StateSetValue {
    case literal(Any)
    case expression(String)
}

/// Alert action configuration
public struct AlertActionConfig {
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
public enum AlertMessage {
    case `static`(String)
    case template(String)  // Contains ${variable} placeholders
}

/// Alert button configuration
public struct AlertButtonConfig {
    public let label: String
    public let style: AlertButtonStyle
    public let action: String?  // Action ID to execute

    public init(label: String, style: AlertButtonStyle = .default, action: String? = nil) {
        self.label = label
        self.style = style
        self.action = action
    }
}
