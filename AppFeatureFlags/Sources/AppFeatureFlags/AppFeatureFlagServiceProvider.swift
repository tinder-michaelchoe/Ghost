//
//  Untitled.swift
//  AppFeatureFlags
//
//  Created by mexicanpizza on 12/25/25.
//

import CoreContracts

/// Service provider for FeatureFlagsService.
/// Registers FeatureFlagsService as a bootstrap service.
public final class AppFeatureFlagServiceProvider: ServiceProvider {
    
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(AppFeatureFlagsService.self, factory: { _ in
            AppFeatureFlagsServiceImpl()
        })
    }
}
