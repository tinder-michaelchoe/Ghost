//
//  SectionLayoutConfigResolverRegistry+Default.swift
//  CladsModules
//
//  Registers default section layout config resolvers.
//

import CLADS
import Foundation

public extension SectionLayoutConfigResolverRegistry {
    
    /// Creates a registry pre-populated with all built-in layout config resolvers.
    static func withBuiltInResolvers() -> SectionLayoutConfigResolverRegistry {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.registerBuiltInResolvers()
        return registry
    }
    
    /// Register all built-in section layout config resolvers.
    ///
    /// Built-in resolvers include:
    /// - List layout
    /// - Grid layout
    /// - Flow layout
    /// - Horizontal layout
    func registerBuiltInResolvers() {
        register(ListLayoutConfigResolver())
        register(GridLayoutConfigResolver())
        register(FlowLayoutConfigResolver())
        register(HorizontalLayoutConfigResolver())
    }
}
