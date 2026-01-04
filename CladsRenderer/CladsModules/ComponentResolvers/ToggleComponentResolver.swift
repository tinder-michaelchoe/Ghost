//
//  ToggleComponentResolver.swift
//  CladsModules
//
//  Resolves toggle components.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves `toggle` components into ToggleNode
public struct ToggleComponentResolver: ComponentResolving {

    public static let componentKind: Document.ComponentKind = .toggle

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
                nodeType: .toggle(ToggleNodeData(
                    bindingPath: bindingPath,
                    style: style
                ))
            )
            viewNode?.parent = context.parentViewNode

            // Track binding as both read and write
            context.tracker?.beginTracking(for: viewNode!)
            if let path = component.bind {
                context.tracker?.recordRead(path)
                context.tracker?.recordWrite(path)
            }
            if let localPath = component.localBind {
                context.tracker?.recordLocalRead(localPath)
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

        let renderNode = RenderNode.toggle(ToggleNode(
            id: component.id,
            bindingPath: component.bind,
            style: style
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
