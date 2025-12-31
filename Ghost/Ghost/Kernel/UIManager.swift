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
    private let registry: UIRegistry
    private var providers: [UIProvider] = []

    init() {
        self.registry = UIRegistry()
    }

    /// Set the service resolver for dependency injection.
    /// Must be called before registering UI providers.
    func setServiceResolver(_ resolver: ServiceResolver) {
        registry.setServiceResolver(resolver)
    }

    /// Register UI providers.
    /// - Parameter providers: Array of UIProvider types to register
    func register(providers: [UIProvider.Type]) async throws {
        print("📋 UIManager: Registering \(providers.count) UI providers")
        for providerType in providers {
            print("  → Registering \(providerType)")
            let instance = providerType.init()
            self.providers.append(instance)
            instance.registerUI(registry)
        }
        print("📋 UIManager: All contributions after registration:")
        for (surface, contribs) in registry.allContributions() {
            print("  → \(surface): \(contribs.count) contribution(s)")
        }
    }

    /// Get resolved contributions for a UI surface.
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of resolved contributions for the surface
    func contributions<T: UISurface>(for surface: T) -> [ResolvedContribution] {
        registry.contributions(for: surface)
    }

    /// Get the UI registry implementation (for direct access if needed).
    var uiRegistry: UIRegistry {
        registry
    }
}
