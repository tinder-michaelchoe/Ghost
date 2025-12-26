//
//  BootstrapManifest.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import CoreContracts
import AppFeatureFlags

/// Manifest for bootstrap services.
/// These services are registered synchronously during app launch.
/// Bootstrap services are NOT part of the Manifest protocol - only BootstrapManifest can provide them.
enum BootstrapManifest {
    
    /// Bootstrap service providers that must be registered before app initialization.
    /// This is separate from the Manifest protocol to prevent other modules from adding bootstrap services.
    static var bootstrapServiceProviders: [ServiceProvider.Type] {
        [
            AppFeatureFlagServiceProvider.self
        ]
    }
}
