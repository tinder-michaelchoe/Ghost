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
enum AppManifest: Manifest {
    
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
        Self.allManifests.forEach { manifest in
            providers += manifest.serviceProviders
        }
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
        Self.allManifests.forEach { manifest in
            participants += manifest.lifecycleParticipants
        }
        return participants
    }
    
    /// All AppDelegate listeners from all sources.
    static var appDelegateListeners: [AppDelegateListener.Type] {
        var listeners: [AppDelegateListener.Type] = []
        Self.allManifests.forEach { manifest in
            listeners += manifest.appDelegateListeners
        }
        return listeners
    }
    
    /// All SceneDelegate listeners from all sources.
    static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        var listeners: [SceneDelegateListener.Type] = []
        Self.allManifests.forEach { manifest in
            listeners += manifest.sceneDelegateListeners
        }
        return listeners
    }
}

