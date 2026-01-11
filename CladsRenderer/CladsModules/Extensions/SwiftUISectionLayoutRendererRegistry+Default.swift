//
//  SwiftUISectionLayoutRendererRegistry+Default.swift
//  CladsModules
//
//  Registers default SwiftUI section layout renderers.
//

import CLADS
import Foundation

public extension SwiftUISectionLayoutRendererRegistry {
    
    /// Creates a registry pre-populated with all built-in section layout renderers.
    static func withBuiltInRenderers() -> SwiftUISectionLayoutRendererRegistry {
        let registry = SwiftUISectionLayoutRendererRegistry()
        registry.registerBuiltInRenderers()
        return registry
    }
    
    /// Register all built-in section layout renderers.
    ///
    /// Built-in renderers include:
    /// - List layout
    /// - Grid layout
    /// - Flow layout
    /// - Horizontal layout
    func registerBuiltInRenderers() {
        register(ListSectionLayoutRenderer())
        register(GridSectionLayoutRenderer())
        register(FlowSectionLayoutRenderer())
        register(HorizontalSectionLayoutRenderer())
    }
}
