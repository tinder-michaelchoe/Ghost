//
//  TabBar+Manifest.swift
//  TabBar
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

public enum TabBarManifest: Manifest {

    /// Returns all service providers from TabBar.
    public static var serviceProviders: [ServiceProvider.Type] {
        [NavigationServiceProvider.self]
    }

    /// Returns all UI providers from TabBarFramework.
    public static var uiProviders: [UIProvider.Type] {
        [
            TabBarUIProvider.self
        ]
    }

    /// Returns all lifecycle participants from TabBarFramework.
    public static var lifecycleParticipants: [LifecycleParticipant.Type] {
        []
    }
}

// MARK: - Service Provider

public final class NavigationServiceProvider: ServiceProvider {

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(NavigationService.self) {
            NavigationServiceHolder()
        }
    }
}
