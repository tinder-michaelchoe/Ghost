//
//  SectionLayoutResolver.swift
//  CladsRendererFramework
//
//  Resolves section layouts (horizontal, list, grid, flow sections).
//

import Foundation
import SwiftUI

/// Resolves SectionLayout nodes into SectionLayoutNode
public struct SectionLayoutResolver: SectionLayoutResolving {

    private let componentRegistry: ComponentResolverRegistry

    public init(componentRegistry: ComponentResolverRegistry = .default) {
        self.componentRegistry = componentRegistry
    }

    @MainActor
    public func resolve(_ sectionLayout: Document.SectionLayout, context: ResolutionContext) throws -> NodeResolutionResult {
        // Create view node if tracking
        let viewNode: ViewNode?
        if context.isTracking {
            viewNode = ViewNode(
                id: sectionLayout.id ?? UUID().uuidString,
                nodeType: .sectionLayout(SectionLayoutNodeData(sectionSpacing: sectionLayout.sectionSpacing ?? 0))
            )
            viewNode?.parent = context.parentViewNode
        } else {
            viewNode = nil
        }

        // Resolve sections
        let childContext = viewNode.map { context.withParent($0) } ?? context
        let sections = try sectionLayout.sections.map { section in
            try resolveSection(section, context: childContext)
        }

        let sectionLayoutNode = SectionLayoutNode(
            id: sectionLayout.id,
            sectionSpacing: sectionLayout.sectionSpacing ?? 0,
            sections: sections
        )

        return NodeResolutionResult(
            renderNode: .sectionLayout(sectionLayoutNode),
            viewNode: viewNode
        )
    }

    // MARK: - Section Resolution

    @MainActor
    private func resolveSection(_ section: Document.SectionDefinition, context: ResolutionContext) throws -> IR.Section {
        let layoutType = resolveSectionType(section.layout, config: section.config)
        let config = resolveSectionConfig(section.config)

        // Resolve header and footer if present
        let header: RenderNode? = try section.header.map { try resolveNode($0, context: context).renderNode }
        let footer: RenderNode? = try section.footer.map { try resolveNode($0, context: context).renderNode }

        // Resolve children - either static or data-driven
        var children: [RenderNode] = []

        if let dataSource = section.dataSource, let template = section.itemTemplate {
            // Data-driven section
            children = try resolveDataDrivenChildren(
                dataSource: dataSource,
                template: template,
                context: context
            )
        } else if let staticChildren = section.children {
            // Static children
            children = try staticChildren.map { try resolveNode($0, context: context).renderNode }
        }

        return IR.Section(
            id: section.id,
            layoutType: layoutType,
            header: header,
            footer: footer,
            stickyHeader: section.stickyHeader ?? false,
            config: config,
            children: children
        )
    }

    // MARK: - Section Type Resolution

    private func resolveSectionType(_ type: Document.SectionType, config: Document.SectionConfig?) -> IR.SectionType {
        switch type {
        case .horizontal:
            return .horizontal
        case .list:
            return .list
        case .grid:
            let columns = resolveSectionColumns(config?.columns)
            return .grid(columns: columns)
        case .flow:
            return .flow
        }
    }

    private func resolveSectionColumns(_ columns: Document.ColumnConfig?) -> IR.ColumnConfig {
        guard let columns = columns else {
            return .fixed(2)  // Default to 2 columns
        }

        switch columns {
        case .fixed(let count):
            return .fixed(count)
        case .adaptive(let minWidth):
            return .adaptive(minWidth: minWidth)
        }
    }

    private func resolveSectionConfig(_ config: Document.SectionConfig?) -> IR.SectionConfig {
        guard let config = config else {
            return IR.SectionConfig()
        }

        return IR.SectionConfig(
            itemSpacing: config.itemSpacing ?? 8,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: PaddingConverter.convert(config.contentInsets),
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: config.isPagingEnabled ?? false,
            showsDividers: config.showsDividers ?? true
        )
    }

    // MARK: - Data-Driven Children

    @MainActor
    private func resolveDataDrivenChildren(
        dataSource: String,
        template: Document.LayoutNode,
        context: ResolutionContext
    ) throws -> [RenderNode] {
        // Get the array from state
        guard let items = context.stateStore.get(dataSource) as? [Any] else {
            return []
        }

        // For each item, resolve the template with the item's data in context
        var children: [RenderNode] = []
        for _ in items {
            // TODO: In a full implementation, we'd set up item context here
            let result = try resolveNode(template, context: context)
            children.append(result.renderNode)
        }
        return children
    }

    // MARK: - Node Resolution

    @MainActor
    private func resolveNode(_ node: Document.LayoutNode, context: ResolutionContext) throws -> NodeResolutionResult {
        switch node {
        case .layout(let layout):
            let layoutResolver = LayoutResolver(componentRegistry: componentRegistry)
            return try layoutResolver.resolve(layout, context: context)

        case .sectionLayout(let sectionLayout):
            return try resolve(sectionLayout, context: context)

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
}
