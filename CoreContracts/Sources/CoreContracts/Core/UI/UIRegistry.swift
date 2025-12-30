//
//  UIRegistry.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

/// Registry for UI contributions.
/// Provides synchronous interface for registering UI contributions.
public protocol UIRegistryContributing: Sendable {
    /// Register a UI contribution to a surface.
    /// - Parameters:
    ///   - surface: The UI surface to contribute to
    ///   - item: The view contribution to register
    func contribute<T: UISurface>(to surface: T, item: some ViewContribution)
    
    /// Get all contributions for a UI surface.
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of view contributions for the surface
    func contributions<T: UISurface>(for surface: T) -> [any ViewContribution]
}
