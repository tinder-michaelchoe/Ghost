//
//  UIRegistryImpl.swift
//  Ghost
//
//  Created by mexicanpizza on 12/22/25.
//

import Foundation
import CoreContracts

/// Thread-safe storage for UI contributions.
/// Uses a serial DispatchQueue for thread safety, providing synchronous interface.
final class UIRegistry: UIRegistryContributing, UIRegistryContributions {
    private let queue = DispatchQueue(label: "com.ghost.uiregistry")
    private var contributions: [AnyHashable: [any ViewContribution]] = [:]
    
    init() {}
    
    // MARK: - UIRegistry
    
    /// Register a UI contribution to a surface (synchronous).
    /// - Parameters:
    ///   - surface: The UI surface to contribute to
    ///   - item: The view contribution to register
    func contribute<T: UISurface>(to surface: T, item: some ViewContribution) {
        queue.sync {
            contributions[AnyHashable(surface), default: []].append(item)
        }
    }
    
    // MARK: - UIRegistryContributions
    
    /// Get all contributions for a UI surface (synchronous).
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of view contributions for the surface
    func contributions<T: UISurface>(for surface: T) -> [any ViewContribution] {
        queue.sync {
            contributions[AnyHashable(surface), default: []]
        }
    }
    
    /// Get all contributions across all surfaces (synchronous).
    /// - Returns: Dictionary mapping surfaces to their contributions
    func allContributions() -> [AnyHashable: [any ViewContribution]] {
        queue.sync {
            contributions
        }
    }
}
