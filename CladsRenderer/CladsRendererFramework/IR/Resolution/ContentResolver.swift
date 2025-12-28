//
//  ContentResolver.swift
//  CladsRendererFramework
//
//  Resolves component content from data sources and bindings.
//

import Foundation

/// Resolves content strings from components, handling data sources and bindings.
public struct ContentResolver {

    /// Resolves content for a component, tracking dependencies if enabled.
    /// - Parameters:
    ///   - component: The component to resolve content for
    ///   - context: The resolution context
    ///   - viewNode: The view node for dependency tracking (optional)
    /// - Returns: The resolved content string
    @MainActor
    public static func resolve(
        _ component: Document.Component,
        context: ResolutionContext,
        viewNode: ViewNode? = nil
    ) -> String {
        // Check for dataSourceId (uses DataSource type)
        if let dataSourceId = component.dataSourceId,
           let dataSource = context.document.dataSources?[dataSourceId] {
            return resolveFromDataSource(dataSource, context: context, viewNode: viewNode)
        }

        // Check for inline data reference (uses DataReference type)
        if let data = component.data {
            return resolveFromDataReference(data, context: context, viewNode: viewNode)
        }

        return component.label ?? ""
    }

    // MARK: - Private Helpers

    @MainActor
    private static func resolveFromDataSource(
        _ dataSource: Document.DataSource,
        context: ResolutionContext,
        viewNode: ViewNode?
    ) -> String {
        switch dataSource.type {
        case .static:
            return dataSource.value ?? ""

        case .binding:
            if let path = dataSource.path {
                context.tracker?.recordRead(path)
                return context.stateStore.get(path) as? String ?? ""
            }
        }
        return ""
    }

    @MainActor
    private static func resolveFromDataReference(
        _ data: Document.DataReference,
        context: ResolutionContext,
        viewNode: ViewNode?
    ) -> String {
        switch data.type {
        case .static:
            return data.value ?? ""

        case .binding:
            if let path = data.path {
                context.tracker?.recordRead(path)
                return context.stateStore.get(path) as? String ?? ""
            }
            if let template = data.template {
                let paths = extractTemplatePaths(template)
                for path in paths {
                    context.tracker?.recordRead(path)
                }
                return context.stateStore.interpolate(template)
            }

        case .localBinding:
            if let path = data.path {
                context.tracker?.recordLocalRead(path)
                return viewNode?.getLocalState(path) as? String ?? ""
            }
        }
        return ""
    }

    /// Extracts state paths from a template string like "Hello ${user.name}!"
    private static func extractTemplatePaths(_ template: String) -> [String] {
        var paths: [String] = []
        let pattern = #"\$\{([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return paths }

        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        for match in matches {
            if let range = Range(match.range(at: 1), in: template) {
                paths.append(String(template[range]))
            }
        }
        return paths
    }
}
