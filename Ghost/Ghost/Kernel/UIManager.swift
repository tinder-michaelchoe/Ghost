//
//  UIManager.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation
import CoreContracts

/// Manages UI contribution registration and querying.
/// Handles UIProvider registration and provides UI contribution access.
final class UIManager {
    private let registry: UIRegistryImpl
    private var providers: [UIProvider] = []
    
    init() {
        self.registry = UIRegistryImpl()
    }
    
    /// Register UI providers.
    /// - Parameter providers: Array of UIProvider types to register
    func register(providers: [UIProvider.Type]) async throws {
        for providerType in providers {
            let instance = providerType.init()
            self.providers.append(instance)
            await instance.registerUI(registry)
        }
    }
    
    /// Get contributions for a UI surface.
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of view contributions for the surface
    func getContributions<T: UISurface>(for surface: T) async -> [any ViewContribution] {
        await registry.getContributions(for: surface)
    }
    
    /// Get the UI registry implementation (for direct access if needed).
    var uiRegistry: UIRegistryImpl {
        registry
    }
}

