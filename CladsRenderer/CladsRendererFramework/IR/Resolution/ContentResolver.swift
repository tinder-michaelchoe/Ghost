//
//  ContentResolver.swift
//  CladsRendererFramework
//
//  Resolves component content from data sources and bindings.
//

import Foundation

/// Result of content resolution, including binding info for reactive updates
public struct ContentResolutionResult {
    /// The resolved content string
    public let content: String

    /// If set, the content should be read dynamically from StateStore at this path
    public let bindingPath: String?

    /// If set, this template should be interpolated with StateStore values (e.g., "Hello ${name}")
    public let bindingTemplate: String?

    /// Whether this content is dynamic and should be observed for changes
    public var isDynamic: Bool {
        bindingPath != nil || bindingTemplate != nil
    }

    public init(content: String, bindingPath: String? = nil, bindingTemplate: String? = nil) {
        self.content = content
        self.bindingPath = bindingPath
        self.bindingTemplate = bindingTemplate
    }

    /// Create a static content result (no binding)
    public static func `static`(_ content: String) -> ContentResolutionResult {
        ContentResolutionResult(content: content)
    }
}

/// Resolves content strings from components, handling data sources and bindings.
public struct ContentResolver {

    /// Resolves content for a component, tracking dependencies if enabled.
    /// - Parameters:
    ///   - component: The component to resolve content for
    ///   - context: The resolution context
    ///   - viewNode: The view node for dependency tracking (optional)
    /// - Returns: The resolved content with binding info
    @MainActor
    public static func resolve(
        _ component: Document.Component,
        context: ResolutionContext,
        viewNode: ViewNode? = nil
    ) -> ContentResolutionResult {
        // Check for dataSourceId (uses DataSource type)
        if let dataSourceId = component.dataSourceId,
           let dataSource = context.document.dataSources?[dataSourceId] {
            return resolveFromDataSource(dataSource, context: context, viewNode: viewNode)
        }

        // Check for inline data reference (uses DataReference type)
        if let data = component.data {
            return resolveFromDataReference(data, context: context, viewNode: viewNode)
        }

        return .static(component.text ?? "")
    }

    // MARK: - Private Helpers

    @MainActor
    private static func resolveFromDataSource(
        _ dataSource: Document.DataSource,
        context: ResolutionContext,
        viewNode: ViewNode?
    ) -> ContentResolutionResult {
        switch dataSource.type {
        case .static:
            return .static(dataSource.value ?? "")

        case .binding:
            if let path = dataSource.path {
                context.tracker?.recordRead(path)
                let content = context.stateStore.get(path) as? String ?? ""
                return ContentResolutionResult(content: content, bindingPath: path)
            }
            if let template = dataSource.template {
                let paths = extractTemplatePaths(template)
                for path in paths {
                    context.tracker?.recordRead(path)
                }
                let content = context.stateStore.interpolate(template)
                return ContentResolutionResult(content: content, bindingTemplate: template)
            }
        }
        return .static("")
    }

    @MainActor
    private static func resolveFromDataReference(
        _ data: Document.DataReference,
        context: ResolutionContext,
        viewNode: ViewNode?
    ) -> ContentResolutionResult {
        switch data.type {
        case .static:
            return .static(data.value ?? "")

        case .binding:
            if let path = data.path {
                context.tracker?.recordRead(path)
                let content = context.stateStore.get(path) as? String ?? ""
                return ContentResolutionResult(content: content, bindingPath: path)
            }
            if let template = data.template {
                let paths = extractTemplatePaths(template)
                for path in paths {
                    context.tracker?.recordRead(path)
                }
                let content = context.stateStore.interpolate(template)
                return ContentResolutionResult(content: content, bindingTemplate: template)
            }

        case .localBinding:
            if let path = data.path {
                context.tracker?.recordLocalRead(path)
                let content = viewNode?.getLocalState(path) as? String ?? ""
                // Local bindings don't use global state store observation
                return .static(content)
            }
        }
        return .static("")
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
