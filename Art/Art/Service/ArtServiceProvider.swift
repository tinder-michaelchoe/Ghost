//
//  ArtServiceProvider.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

/// Service provider that registers the ArtSearching service.
/// Depends on NetworkRequestPerforming.
public final class ArtServiceProvider: ServiceProvider {
    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(
            ArtSearching.self,
            dependencies: (NetworkRequestPerforming.self)
        ) { networkClient in
            ArtService(networkClient: networkClient)
        }
    }
}
