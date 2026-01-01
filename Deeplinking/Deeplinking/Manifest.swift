//
//  Manifest.swift
//  Deeplinking
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

public enum DeeplinkingManifest: Manifest {

    public static var serviceProviders: [ServiceProvider.Type] {
        [DeeplinkServiceProvider.self]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [DeeplinkSceneDelegateListener.self]
    }
}

// MARK: - Service Provider

public final class DeeplinkServiceProvider: ServiceProvider {

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(DeeplinkService.self) {
            DeeplinkRouter()
        }
    }
}
