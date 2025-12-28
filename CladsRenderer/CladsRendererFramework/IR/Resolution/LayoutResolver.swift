//
//  LayoutResolver.swift
//  CladsRendererFramework
//
//  Resolves layout containers (VStack, HStack, ZStack).
//

import Foundation
import SwiftUI

/// Resolves Layout nodes into ContainerNode
public struct LayoutResolver: LayoutResolving {

    private let componentRegistry: ComponentResolverRegistry

    public init(componentRegistry: ComponentResolverRegistry = .default) {
        self.componentRegistry = componentRegistry
    }

    @MainActor
    public func resolve(_ layout: Document.Layout, context: ResolutionContext) throws -> NodeResolutionResult {
        let (layoutType, alignment) = resolveLayoutTypeAndAlignment(layout)
        let padding = PaddingConverter.convert(layout.padding)

        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: UUID().uuidString,
                nodeType: .container(ContainerNodeData(
                    layoutType: layoutType,
                    alignment: alignment,
                    spacing: layout.spacing ?? 0,
                    padding: padding,
                    style: IR.Style()
                ))
            )
            viewNode?.parent = context.parentViewNode

            // Initialize local state if declared
            if let localState = layout.state {
                initializeLocalState(on: viewNode!, from: localState)
            }
        } else {
            viewNode = nil
        }

        // Resolve children with updated context
        let childContext = viewNode.map { context.withParent($0) } ?? context
        let (renderChildren, viewChildren) = try resolveChildren(layout.children, context: childContext)

        // Attach view children
        if let viewNode = viewNode {
            viewNode.children = viewChildren
        }

        let containerNode = ContainerNode(
            id: nil,
            layoutType: layoutType,
            alignment: alignment,
            spacing: layout.spacing ?? 0,
            padding: padding,
            style: IR.Style(),
            children: renderChildren
        )

        return NodeResolutionResult(
            renderNode: .container(containerNode),
            viewNode: viewNode
        )
    }

    // MARK: - Private Helpers

    private func resolveLayoutTypeAndAlignment(_ layout: Document.Layout) -> (ContainerNode.LayoutType, SwiftUI.Alignment) {
        switch layout.type {
        case .vstack:
            return (.vstack, AlignmentConverter.forVStack(layout.horizontalAlignment))
        case .hstack:
            return (.hstack, AlignmentConverter.forHStack(layout.alignment?.vertical))
        case .zstack:
            return (.zstack, AlignmentConverter.forZStack(layout.alignment))
        }
    }

    @MainActor
    private func resolveChildren(
        _ children: [Document.LayoutNode],
        context: ResolutionContext
    ) throws -> ([RenderNode], [ViewNode]) {
        var renderChildren: [RenderNode] = []
        var viewChildren: [ViewNode] = []

        for child in children {
            let result = try resolveNode(child, context: context)
            renderChildren.append(result.renderNode)
            if let viewNode = result.viewNode {
                viewChildren.append(viewNode)
            }
        }

        return (renderChildren, viewChildren)
    }

    @MainActor
    private func resolveNode(_ node: Document.LayoutNode, context: ResolutionContext) throws -> NodeResolutionResult {
        switch node {
        case .layout(let layout):
            return try resolve(layout, context: context)

        case .sectionLayout(let sectionLayout):
            let sectionResolver = SectionLayoutResolver(componentRegistry: componentRegistry)
            return try sectionResolver.resolve(sectionLayout, context: context)

        case .component(let component):
            let result = try componentRegistry.resolve(component, context: context)
            return NodeResolutionResult(renderNode: result.renderNode, viewNode: result.viewNode)

        case .spacer:
            let viewNode: ViewNode?
            if context.isTracking {
                viewNode = ViewNode(id: UUID().uuidString, nodeType: .spacer)
                viewNode?.parent = context.parentViewNode
            } else {
                viewNode = nil
            }
            return NodeResolutionResult(renderNode: .spacer, viewNode: viewNode)
        }
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
