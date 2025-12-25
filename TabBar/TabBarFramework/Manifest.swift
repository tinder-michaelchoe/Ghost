//
//  TabBar+Manifest.swift
//  TabBar
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

public enum TabBarManifest: Manifest {
    
    /// Returns all service providers from AppFoundation.
    public static var serviceProviders: [ServiceProvider.Type] {
        []
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
    
    /// Returns all modules with identity (for dependency resolution).
    public static var modulesWithIdentity: [any ModuleIdentity.Type] {
        [
            TabBarUIProvider.self
        ]
    }
}
