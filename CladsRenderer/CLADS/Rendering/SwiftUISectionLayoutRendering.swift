//
//  SwiftUISectionLayoutRendering.swift
//  CLADS
//
//  Protocol and registry for rendering section layouts in SwiftUI.
//

import Foundation
import SwiftUI

// MARK: - Section Layout Type Identifier

/// Type-safe identifier for section layout types.
///
/// Use this to register and look up section layout renderers.
public struct SectionLayoutTypeIdentifier: Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension SectionLayoutTypeIdentifier {
    public static let list = SectionLayoutTypeIdentifier(rawValue: "list")
    public static let grid = SectionLayoutTypeIdentifier(rawValue: "grid")
    public static let flow = SectionLayoutTypeIdentifier(rawValue: "flow")
    public static let horizontal = SectionLayoutTypeIdentifier(rawValue: "horizontal")
}

// MARK: - SwiftUI Section Layout Rendering Protocol

/// Protocol for rendering a specific section layout type in SwiftUI.
///
/// Implement this protocol to add support for new section layout types.
///
/// Example:
/// ```swift
/// struct CarouselSectionLayoutRenderer: SwiftUISectionLayoutRendering {
///     static let layoutTypeIdentifier = SectionLayoutTypeIdentifier(rawValue: "carousel")
///
///     func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
///         // Custom carousel rendering
///     }
/// }
/// ```
public protocol SwiftUISectionLayoutRendering {
    /// The layout type this renderer handles
    static var layoutTypeIdentifier: SectionLayoutTypeIdentifier { get }
    
    /// Render a section with this layout type
    /// - Parameters:
    ///   - section: The section to render
    ///   - context: The render context with access to child rendering
    /// - Returns: The rendered SwiftUI view
    @MainActor
    func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView
}

// MARK: - Section Render Context

/// Context provided to section layout renderers.
public struct SwiftUISectionRenderContext {
    /// The parent SwiftUI render context
    public let parentContext: SwiftUIRenderContext
    
    public init(parentContext: SwiftUIRenderContext) {
        self.parentContext = parentContext
    }
    
    /// Render a child node
    @MainActor
    public func renderChild(_ node: RenderNode) -> AnyView {
        parentContext.render(node)
    }
}

// MARK: - SwiftUI Section Layout Renderer Registry

/// Registry for SwiftUI section layout renderers.
///
/// Register renderers for different layout types to enable extensible layout rendering.
public final class SwiftUISectionLayoutRendererRegistry: @unchecked Sendable {
    
    private var renderers: [SectionLayoutTypeIdentifier: any SwiftUISectionLayoutRendering] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    /// Register a renderer for a specific layout type
    public func register<R: SwiftUISectionLayoutRendering>(_ renderer: R) {
        lock.lock()
        defer { lock.unlock() }
        renderers[R.layoutTypeIdentifier] = renderer
    }
    
    /// Check if a renderer exists for the given layout type
    public func hasRenderer(for identifier: SectionLayoutTypeIdentifier) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return renderers[identifier] != nil
    }
    
    /// Get the renderer for a section type
    public func renderer(for sectionType: IR.SectionType) -> (any SwiftUISectionLayoutRendering)? {
        let identifier = sectionType.layoutTypeIdentifier
        lock.lock()
        let renderer = renderers[identifier]
        lock.unlock()
        return renderer
    }
    
    /// Render a section using the appropriate registered renderer
    /// - Returns: The rendered view, or nil if no renderer is registered
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView? {
        guard let renderer = renderer(for: section.layoutType) else {
            return nil
        }
        return renderer.render(section: section, context: context)
    }
}

// MARK: - Section Type Extension

extension IR.SectionType {
    /// Get the layout type identifier for registry lookup
    public var layoutTypeIdentifier: SectionLayoutTypeIdentifier {
        switch self {
        case .list:
            return .list
        case .grid:
            return .grid
        case .flow:
            return .flow
        case .horizontal:
            return .horizontal
        }
    }
}
