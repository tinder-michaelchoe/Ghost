//
//  TextFieldComponentResolver.swift
//  CladsModules
//
//  Resolves textfield components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `textfield` components into TextFieldNode
public struct TextFieldComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .textfield

    public init() {}

    @MainActor
    public func resolve(_ component: Document.Component, context: ResolutionContext) throws -> ComponentResolutionResult {
        let style = context.styleResolver.resolve(component.styleId)
        let nodeId = component.id ?? UUID().uuidString

        // Resolve binding path (global or local)
        let bindingPath = component.bind ?? component.localBind.map { "local.\($0)" }

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: nodeId,
                nodeType: .textField(TextFieldNodeData(
                    placeholder: component.placeholder ?? "",
                    style: style,
                    bindingPath: bindingPath
                ))
            )
            viewNode?.parent = context.parentViewNode

            // Track binding as both read and write
            context.tracker?.beginTracking(for: viewNode!)
            if let path = component.bind {
                context.tracker?.recordWrite(path)
            }
            if let localPath = component.localBind {
                context.tracker?.recordLocalWrite(localPath)
            }
            context.tracker?.endTracking()
        } else {
            viewNode = nil
        }

        // Initialize local state if declared
        if let viewNode = viewNode, let localState = component.state {
            initializeLocalState(on: viewNode, from: localState)
        }

        let renderNode = RenderNode.textField(TextFieldNode(
            id: component.id,
            placeholder: component.placeholder ?? "",
            style: style,
            bindingPath: component.bind
        ))

        return ComponentResolutionResult(renderNode: renderNode, viewNode: viewNode)
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
