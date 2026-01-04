//
//  ComponentRegistration.swift
//  CLADS
//
//  Unified API for registering custom components.
//  Provides a single entry point for the full component pipeline.
//

import Foundation

// MARK: - Component Registration

/// Unified API for registering custom components in CLADS.
///
/// This provides a single entry point for registering all the pieces needed
/// for a custom component: properties decoder, resolver, and renderers.
///
/// Example usage:
/// ```swift
/// // Define your component pieces
/// extension Document.ComponentKind {
///     static let chart = Document.ComponentKind(rawValue: "chart")
/// }
///
/// extension RenderNodeKind {
///     static let chart = RenderNodeKind(rawValue: "chart")
/// }
///
/// struct ChartProperties: ComponentProperties {
///     static let kind = Document.ComponentKind.chart
///     let dataPoints: [Double]
///     let chartType: String
/// }
///
/// struct ChartNode: CustomRenderNode {
///     static let kind = RenderNodeKind.chart
///     let dataPoints: [Double]
///     let chartType: String
///     let style: IR.Style
/// }
///
/// struct ChartResolver: ComponentResolving { ... }
/// struct ChartUIKitRenderer: UIKitNodeRendering { ... }
/// struct ChartSwiftUIRenderer: SwiftUINodeRendering { ... }
///
/// // Register everything at once
/// let registry = CladsRegistry()
/// registry.registerComponent(
///     propertiesType: ChartProperties.self,
///     resolver: ChartResolver(),
///     uikitRenderer: ChartUIKitRenderer(),
///     swiftuiRenderer: ChartSwiftUIRenderer()
/// )
/// ```
public final class CladsRegistry: @unchecked Sendable {

    // MARK: - Dependencies

    private let propertiesRegistry: ComponentPropertiesRegistry
    private let componentRegistry: ComponentResolverRegistry
    private let uikitRegistry: UIKitNodeRendererRegistry
    private let swiftuiRegistry: SwiftUINodeRendererRegistry
    private let actionRegistry: ActionRegistry

    // MARK: - Initialization

    /// Creates a registry with new empty registries
    public convenience init() {
        self.init(
            propertiesRegistry: ComponentPropertiesRegistry(),
            componentRegistry: ComponentResolverRegistry(),
            uikitRegistry: UIKitNodeRendererRegistry(),
            swiftuiRegistry: SwiftUINodeRendererRegistry(),
            actionRegistry: ActionRegistry()
        )
    }

    /// Creates a registry with custom registries
    public init(
        propertiesRegistry: ComponentPropertiesRegistry,
        componentRegistry: ComponentResolverRegistry,
        uikitRegistry: UIKitNodeRendererRegistry,
        swiftuiRegistry: SwiftUINodeRendererRegistry,
        actionRegistry: ActionRegistry
    ) {
        self.propertiesRegistry = propertiesRegistry
        self.componentRegistry = componentRegistry
        self.uikitRegistry = uikitRegistry
        self.swiftuiRegistry = swiftuiRegistry
        self.actionRegistry = actionRegistry
    }

    // MARK: - Full Registration

    /// Registers a complete custom component with all pipeline stages.
    ///
    /// - Parameters:
    ///   - propertiesType: The type for decoding component-specific properties from JSON
    ///   - resolver: The resolver that converts Document.Component to RenderNode
    ///   - uikitRenderer: The renderer for UIKit
    ///   - swiftuiRenderer: The renderer for SwiftUI
    public func registerComponent<
        P: ComponentProperties,
        R: ComponentResolving,
        U: UIKitNodeRendering,
        S: SwiftUINodeRendering
    >(
        propertiesType: P.Type,
        resolver: R,
        uikitRenderer: U,
        swiftuiRenderer: S
    ) {
        propertiesRegistry.register(propertiesType)
        componentRegistry.register(resolver)
        uikitRegistry.register(uikitRenderer)
        swiftuiRegistry.register(swiftuiRenderer)
    }

    /// Registers a custom component with resolver and SwiftUI renderer only.
    ///
    /// Use this when you only need SwiftUI rendering.
    public func registerComponent<
        P: ComponentProperties,
        R: ComponentResolving,
        S: SwiftUINodeRendering
    >(
        propertiesType: P.Type,
        resolver: R,
        swiftuiRenderer: S
    ) {
        propertiesRegistry.register(propertiesType)
        componentRegistry.register(resolver)
        swiftuiRegistry.register(swiftuiRenderer)
    }

    /// Registers a custom component with resolver and UIKit renderer only.
    ///
    /// Use this when you only need UIKit rendering.
    public func registerComponent<
        P: ComponentProperties,
        R: ComponentResolving,
        U: UIKitNodeRendering
    >(
        propertiesType: P.Type,
        resolver: R,
        uikitRenderer: U
    ) {
        propertiesRegistry.register(propertiesType)
        componentRegistry.register(resolver)
        uikitRegistry.register(uikitRenderer)
    }

    /// Registers a custom component with resolver only (no custom renderers).
    ///
    /// Use this when the component uses built-in render nodes.
    public func registerComponent<
        P: ComponentProperties,
        R: ComponentResolving
    >(
        propertiesType: P.Type,
        resolver: R
    ) {
        propertiesRegistry.register(propertiesType)
        componentRegistry.register(resolver)
    }

    // MARK: - Individual Registration

    /// Registers just a component properties type
    public func registerProperties<P: ComponentProperties>(_ type: P.Type) {
        propertiesRegistry.register(type)
    }

    /// Registers just a component resolver
    public func registerResolver<R: ComponentResolving>(_ resolver: R) {
        componentRegistry.register(resolver)
    }

    /// Registers just a UIKit node renderer
    public func registerUIKitRenderer<U: UIKitNodeRendering>(_ renderer: U) {
        uikitRegistry.register(renderer)
    }

    /// Registers just a SwiftUI node renderer
    public func registerSwiftUIRenderer<S: SwiftUINodeRendering>(_ renderer: S) {
        swiftuiRegistry.register(renderer)
    }

    /// Registers just an action handler
    public func registerAction<A: ActionHandler>(_ handler: A) {
        actionRegistry.register(handler)
    }
}

// MARK: - Component Plugin Protocol

/// Protocol for bundling related component registrations.
///
/// Implement this to create a plugin that registers multiple related components,
/// actions, or other extensions.
///
/// Example:
/// ```swift
/// struct ChartingPlugin: CLADSPlugin {
///     func register(with registry: CladsRegistry) {
///         registry.registerComponent(
///             propertiesType: BarChartProperties.self,
///             resolver: BarChartResolver(),
///             swiftuiRenderer: BarChartSwiftUIRenderer()
///         )
///         registry.registerComponent(
///             propertiesType: LineChartProperties.self,
///             resolver: LineChartResolver(),
///             swiftuiRenderer: LineChartSwiftUIRenderer()
///         )
///     }
/// }
///
/// // Usage
/// ChartingPlugin().register(with: .shared)
/// ```
public protocol CLADSPlugin {
    /// Called to register all components and extensions provided by this plugin
    /// - Parameter registry: The registry to register components with
    func register(with registry: CladsRegistry)
}

// MARK: - Plugin Loading

extension CladsRegistry {
    /// Loads a plugin and registers its components
    /// - Parameter plugin: The plugin to load
    public func load(_ plugin: CLADSPlugin) {
        plugin.register(with: self)
    }

    /// Loads multiple plugins and registers their components
    /// - Parameter plugins: The plugins to load
    public func load(_ plugins: [CLADSPlugin]) {
        for plugin in plugins {
            plugin.register(with: self)
        }
    }
}
