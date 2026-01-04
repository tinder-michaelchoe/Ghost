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

    public init(componentRegistry: ComponentResolverRegistry) {
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
    public func resolveNode(_ node: Document.LayoutNode, context: ResolutionContext) throws -> NodeResolutionResult {
        switch node {
        case .layout(let layout):
            return try resolve(layout, context: context)

        case .sectionLayout(let sectionLayout):
            let sectionResolver = SectionLayoutResolver(componentRegistry: componentRegistry)
            return try sectionResolver.resolve(sectionLayout, context: context)

        case .forEach(let forEach):
            return try resolveForEach(forEach, context: context)

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

    // MARK: - ForEach Resolution

    @MainActor
    private func resolveForEach(_ forEach: Document.ForEach, context: ResolutionContext) throws -> NodeResolutionResult {
        // Get the array from state
        guard let array = context.stateStore.getArray(forEach.items) else {
            // Array not found or empty - show empty view if provided
            if let emptyView = forEach.emptyView {
                return try resolveNode(emptyView, context: context)
            }
            // Return empty container
            return createEmptyContainer(forEach: forEach, context: context)
        }

        // If array is empty, show empty view
        if array.isEmpty {
            if let emptyView = forEach.emptyView {
                return try resolveNode(emptyView, context: context)
            }
            return createEmptyContainer(forEach: forEach, context: context)
        }

        // Resolve layout type and alignment
        let (layoutType, alignment) = resolveForEachLayoutType(forEach)
        let padding = PaddingConverter.convert(forEach.padding)

        // Create view node for the container
        let containerViewNode: ViewNode?
        if context.isTracking {
            containerViewNode = ViewNode(
                id: "forEach_\(forEach.items)",
                nodeType: .container(ContainerNodeData(
                    layoutType: layoutType,
                    alignment: alignment,
                    spacing: forEach.spacing ?? 0,
                    padding: padding,
                    style: IR.Style()
                ))
            )
            containerViewNode?.parent = context.parentViewNode
        } else {
            containerViewNode = nil
        }

        // Resolve each item
        var renderChildren: [RenderNode] = []
        var viewChildren: [ViewNode] = []

        for (index, item) in array.enumerated() {
            // Create context with iteration variables
            let itemContext = context
                .withIterationVariables([
                    forEach.itemVariable: item,
                    forEach.indexVariable: index
                ])

            // Update parent if tracking
            let resolveContext = containerViewNode.map { itemContext.withParent($0) } ?? itemContext

            // Resolve the template
            let result = try resolveNode(forEach.template, context: resolveContext)
            renderChildren.append(result.renderNode)
            if let viewNode = result.viewNode {
                viewChildren.append(viewNode)
            }
        }

        // Attach view children
        if let containerViewNode = containerViewNode {
            containerViewNode.children = viewChildren
        }

        let containerNode = ContainerNode(
            id: "forEach_\(forEach.items)",
            layoutType: layoutType,
            alignment: alignment,
            spacing: forEach.spacing ?? 0,
            padding: padding,
            style: IR.Style(),
            children: renderChildren
        )

        return NodeResolutionResult(
            renderNode: .container(containerNode),
            viewNode: containerViewNode
        )
    }

    private func resolveForEachLayoutType(_ forEach: Document.ForEach) -> (ContainerNode.LayoutType, SwiftUI.Alignment) {
        switch forEach.layout {
        case .vstack:
            return (.vstack, AlignmentConverter.forVStack(forEach.alignment))
        case .hstack:
            return (.hstack, .center)
        case .zstack:
            return (.zstack, .center)
        }
    }

    private func createEmptyContainer(forEach: Document.ForEach, context: ResolutionContext) -> NodeResolutionResult {
        let (layoutType, alignment) = resolveForEachLayoutType(forEach)
        let padding = PaddingConverter.convert(forEach.padding)

        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: "forEach_\(forEach.items)_empty",
                nodeType: .container(ContainerNodeData(
                    layoutType: layoutType,
                    alignment: alignment,
                    spacing: forEach.spacing ?? 0,
                    padding: padding,
                    style: IR.Style()
                ))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        let containerNode = ContainerNode(
            id: "forEach_\(forEach.items)_empty",
            layoutType: layoutType,
            alignment: alignment,
            spacing: forEach.spacing ?? 0,
            padding: padding,
            style: IR.Style(),
            children: []
        )

        return NodeResolutionResult(
            renderNode: .container(containerNode),
            viewNode: viewNode
        )
    }

    private func initializeLocalState(on viewNode: ViewNode, from localState: Document.LocalStateDeclaration) {
        var stateDict: [String: Any] = [:]
        for (key, value) in localState.initialValues {
            stateDict[key] = StateValueConverter.unwrap(value)
        }
        viewNode.localState = stateDict
    }
}
