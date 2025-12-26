//
//  FeatureFlagServiceProvider.swift
//  FeatureFlags
//
//  Created by mexicanpizza on 12/25/25.
//

import CoreContracts

/// Service provider for FeatureFlagsService.
/// Registers FeatureFlagsService as a bootstrap service.
public final class FeatureFlagServiceProvider: ServiceProvider {
    
    public init() {}
    
    public     func registerServices(_ registry: ServiceRegistry) {
        registry.register(FeatureFlagsService.self, factory: { _ in
            FeatureFlagsServiceImpl()
        })
    }
}

