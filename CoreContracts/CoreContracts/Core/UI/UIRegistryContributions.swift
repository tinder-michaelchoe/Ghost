//
//  UIRegistryContributions.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for querying UI registry contributions.
/// This allows modules like TabBar to query for contributions from specific surfaces.
public protocol UIRegistryContributions {
    /// Get all contributions for a UI surface.
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of view contributions for the surface
    func contributions<T: UISurface>(for surface: T) -> [any ViewContribution]
}

