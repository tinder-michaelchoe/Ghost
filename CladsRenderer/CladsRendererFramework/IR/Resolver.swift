//
//  Resolver.swift
//  CladsRendererFramework
//
//  Resolves a Document (AST) into a RenderTree (IR).
//  Handles style inheritance, data binding, and reference validation.
//

import Foundation
import SwiftUI

// MARK: - Resolver

/// Resolves a Document into a RenderTree
public struct Resolver {
    private let styleResolver: StyleResolver
    private let document: Document

    public init(document: Document) {
        self.document = document
        self.styleResolver = StyleResolver(styles: document.styles)
    }

    /// Resolve the document into a render tree
    @MainActor
    public func resolve() throws -> RenderTree {
        let stateStore = StateStore()
        stateStore.initialize(from: document.state)

        let actions = try resolveActions(document.actions ?? [:])
        let rootNode = try resolveRoot(document.root, stateStore: stateStore)

        return RenderTree(
            root: rootNode,
            stateStore: stateStore,
            actions: actions
        )
    }

    // MARK: - Root Resolution

    @MainActor
    private func resolveRoot(_ root: RootComponent, stateStore: StateStore) throws -> RootNode {
        let backgroundColor: Color? = root.backgroundColor.map { Color(hex: $0) }
        let style = styleResolver.resolve(root.styleId)
        let children = try root.children.map { try resolveNode($0, stateStore: stateStore) }

        return RootNode(
            backgroundColor: backgroundColor,
            edgeInsets: root.edgeInsets,
            style: style,
            children: children
        )
    }

    // MARK: - Node Resolution

    @MainActor
    private func resolveNode(_ node: LayoutNode, stateStore: StateStore) throws -> RenderNode {
        switch node {
        case .layout(let layout):
            return .container(try resolveLayout(layout, stateStore: stateStore))
        case .component(let component):
            return try resolveComponent(component, stateStore: stateStore)
        case .spacer:
            return .spacer
        }
    }

    // MARK: - Layout Resolution

    @MainActor
    private func resolveLayout(_ layout: Layout, stateStore: StateStore) throws -> ContainerNode {
        let axis: Axis
        let alignment: ContainerAlignment

        switch layout.type {
        case .vstack:
            axis = .vertical
            alignment = resolveHorizontalAlignment(layout.horizontalAlignment)
        case .hstack:
            axis = .horizontal
            alignment = resolveVerticalAlignment(layout.alignment?.vertical)
        case .zstack:
            axis = .vertical  // ZStack doesn't really have an axis
            alignment = .center
        }

        let padding = resolvePadding(layout.padding)
        let children = try layout.children.map { try resolveNode($0, stateStore: stateStore) }

        return ContainerNode(
            id: nil,
            axis: axis,
            alignment: alignment,
            spacing: layout.spacing ?? 0,
            padding: padding,
            style: ResolvedStyle(),
            children: children
        )
    }

    private func resolveHorizontalAlignment(_ alignment: HorizontalAlignment?) -> ContainerAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center, .none: return .center
        }
    }

    private func resolveVerticalAlignment(_ alignment: VerticalAlignment?) -> ContainerAlignment {
        switch alignment {
        case .top: return .top
        case .bottom: return .bottom
        case .center, .none: return .center
        }
    }

    private func resolvePadding(_ padding: Padding?) -> ResolvedPadding {
        guard let padding = padding else { return ResolvedPadding() }
        return ResolvedPadding(
            top: padding.resolvedTop,
            bottom: padding.resolvedBottom,
            leading: padding.resolvedLeading,
            trailing: padding.resolvedTrailing
        )
    }

    // MARK: - Component Resolution

    @MainActor
    private func resolveComponent(_ component: Component, stateStore: StateStore) throws -> RenderNode {
        let style = styleResolver.resolve(component.styleId)
        let content = resolveContent(component, stateStore: stateStore)

        switch component.type {
        case .label:
            return .text(TextNode(
                id: component.id,
                content: content,
                style: style
            ))

        case .button:
            let onTap = component.actions?.onTap
            return .button(ButtonNode(
                id: component.id,
                label: component.label ?? content,
                style: style,
                fillWidth: component.fillWidth ?? false,
                onTap: onTap
            ))

        case .textfield:
            return .textField(TextFieldNode(
                id: component.id,
                placeholder: component.placeholder ?? "",
                style: style,
                bindingPath: component.bind
            ))

        case .image:
            let source = resolveImageSource(component)
            return .image(ImageNode(
                id: component.id,
                source: source,
                style: style
            ))
        }
    }

    @MainActor
    private func resolveContent(_ component: Component, stateStore: StateStore) -> String {
        // First check for dataSourceId
        if let dataSourceId = component.dataSourceId,
           let dataSource = document.dataSources?[dataSourceId] {
            switch dataSource.type {
            case .static:
                return dataSource.value ?? ""
            case .binding:
                if let path = dataSource.path {
                    return stateStore.get(path) as? String ?? ""
                }
            }
        }

        // Fall back to label
        return component.label ?? ""
    }

    private func resolveImageSource(_ component: Component) -> ImageSource {
        // Check the data property for image source
        if let data = component.data {
            switch data.type {
            case .static:
                if let value = data.value {
                    // Check for system: prefix for SF Symbols
                    if value.hasPrefix("system:") {
                        return .system(name: String(value.dropFirst(7)))
                    }
                    // Check for url: prefix
                    if value.hasPrefix("url:"), let url = URL(string: String(value.dropFirst(4))) {
                        return .url(url)
                    }
                    // Default to asset
                    return .asset(name: value)
                }
            case .binding:
                break  // Dynamic images not supported yet
            }
        }
        return .system(name: "questionmark")
    }

    // MARK: - Action Resolution

    private func resolveActions(_ actions: [String: [String: Any]]) throws -> [String: ActionDefinition] {
        var resolved: [String: ActionDefinition] = [:]
        for (id, actionDict) in actions {
            resolved[id] = try resolveAction(actionDict)
        }
        return resolved
    }

    private func resolveAction(_ dict: [String: Any]) throws -> ActionDefinition {
        guard let type = dict["type"] as? String else {
            throw ResolutionError.invalidAction("Missing 'type' field")
        }

        switch type {
        case "dismiss":
            return .dismiss

        case "setState":
            guard let path = dict["path"] as? String else {
                throw ResolutionError.invalidAction("setState missing 'path'")
            }
            let value = resolveStateValue(dict["value"])
            return .setState(path: path, value: value)

        case "showAlert":
            let title = dict["title"] as? String ?? "Alert"
            let message = resolveAlertMessage(dict["message"])
            let buttons = resolveAlertButtons(dict["buttons"] as? [[String: Any]] ?? [])
            return .showAlert(config: AlertActionConfig(title: title, message: message, buttons: buttons))

        case "sequence":
            guard let steps = dict["steps"] as? [[String: Any]] else {
                throw ResolutionError.invalidAction("sequence missing 'steps'")
            }
            let resolvedSteps = try steps.map { try resolveAction($0) }
            return .sequence(steps: resolvedSteps)

        case "navigate":
            guard let destination = dict["destination"] as? String else {
                throw ResolutionError.invalidAction("navigate missing 'destination'")
            }
            let presentationStr = dict["presentation"] as? String ?? "push"
            let presentation = NavigationPresentation(rawValue: presentationStr) ?? .push
            return .navigate(destination: destination, presentation: presentation)

        default:
            return .custom(type: type, parameters: dict)
        }
    }

    private func resolveStateValue(_ value: Any?) -> StateSetValue {
        guard let value = value else { return .literal(0) }

        if let dict = value as? [String: Any],
           let expr = dict["$expr"] as? String {
            return .expression(expr)
        }

        return .literal(value)
    }

    private func resolveAlertMessage(_ value: Any?) -> AlertMessage? {
        guard let value = value else { return nil }

        if let string = value as? String {
            return .static(string)
        }

        if let dict = value as? [String: Any],
           let type = dict["type"] as? String,
           type == "binding",
           let template = dict["template"] as? String {
            return .template(template)
        }

        return nil
    }

    private func resolveAlertButtons(_ buttons: [[String: Any]]) -> [AlertButtonConfig] {
        return buttons.map { dict in
            let label = dict["label"] as? String ?? "OK"
            let styleStr = dict["style"] as? String ?? "default"
            let style: AlertButtonStyle
            switch styleStr {
            case "cancel": style = .cancel
            case "destructive": style = .destructive
            default: style = .default
            }
            let action = dict["action"] as? String
            return AlertButtonConfig(label: label, style: style, action: action)
        }
    }
}

// MARK: - Resolution Errors

public enum ResolutionError: Error, LocalizedError {
    case unknownStyle(String)
    case unknownDataSource(String)
    case unknownAction(String)
    case invalidAction(String)

    public var errorDescription: String? {
        switch self {
        case .unknownStyle(let id):
            return "Unknown style: '\(id)'"
        case .unknownDataSource(let id):
            return "Unknown data source: '\(id)'"
        case .unknownAction(let id):
            return "Unknown action: '\(id)'"
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        }
    }
}
