//
//  ModuleManifest.swift
//  Ghost
//
//  Created by mexicanpizza on 12/23/25.
//

import AppFoundation
import BuilderFramework
import CoreContracts
import Foundation
import SettingsFramework
import StaticExamplesFramework
import TabBarFramework

/// Central manifest of all modules in the app.
/// This aggregates modules from AppFoundation and app-specific modules.
enum ModuleManifest: Manifest {
    
    private static let allManifests: [Manifest.Type] = [
        AppFoundationModules.self,
        BuilderManifest.self,
        StaticExamplesManifest.self,
        SettingsManifest.self,
        TabBarManifest.self,
    ]
    
    /// All service providers from all sources.
    static var serviceProviders: [ServiceProvider.Type] {
        var providers: [ServiceProvider.Type] = []
        
        // Add service providers from AppFoundation
        providers.append(contentsOf: AppFoundationModules.serviceProviders)
        
        // Add app-specific service providers
        // providers.append(contentsOf: [])
        
        return providers
    }
    
    /// All UI providers from all sources.
    static var uiProviders: [UIProvider.Type] {
        var providers: [UIProvider.Type] = []
        Self.allManifests.forEach { manifest in
            providers += manifest.uiProviders
        }
        return providers
    }
    
    /// All lifecycle participants from all sources.
    static var lifecycleParticipants: [LifecycleParticipant.Type] {
        var participants: [LifecycleParticipant.Type] = []
        
        // Add lifecycle participants from AppFoundation
        participants.append(contentsOf: AppFoundationModules.lifecycleParticipants)
        
        // Add app-specific lifecycle participants
        // participants.append(contentsOf: [])
        
        return participants
    }
}

