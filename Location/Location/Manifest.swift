//
//  Manifest.swift
//  Location
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

// MARK: - Location Manifest

public enum LocationManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [LocationServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        []
    }
}

// MARK: - Location Service Provider

/// Service provider that registers the LocationService.
public final class LocationServiceProvider: ServiceProvider {

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(LocationService.self) {
            CoreLocationService()
        }
    }
}
