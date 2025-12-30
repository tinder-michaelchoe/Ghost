//
//  ModuleManifest.swift
//  Ghost
//
//  Created by mexicanpizza on 12/23/25.
//

import AppFoundation
import Builder
import CladsExamples
import CoreContracts
import Dashboard
import Foundation
import NetworkClient
import TabBar

/// Central manifest of all modules in the app.
/// This aggregates modules from AppFoundation and app-specific modules.
enum AppManifest: Manifest {

    private static let allManifests: [Manifest.Type] = [
        AppFoundationModules.self,
        BuilderManifest.self,
        CladsExamplesManifest.self,
        TabBarManifest.self,
    ] + dashboardFeature

    /// Deduplicates manifests by type identity, preserving order.
    private static var uniqueManifests: [Manifest.Type] {
        var seen = Set<ObjectIdentifier>()
        return allManifests.filter { manifest in
            let id = ObjectIdentifier(manifest)
            if seen.contains(id) {
                return false
            }
            seen.insert(id)
            return true
        }
    }

    /// All service providers from all sources.
    static var serviceProviders: [ServiceProvider.Type] {
        var providers: [ServiceProvider.Type] = []
        uniqueManifests.forEach { manifest in
            providers += manifest.serviceProviders
        }
        return providers
    }

    /// All UI providers from all sources.
    static var uiProviders: [UIProvider.Type] {
        var providers: [UIProvider.Type] = []
        uniqueManifests.forEach { manifest in
            providers += manifest.uiProviders
        }
        return providers
    }

    /// All lifecycle participants from all sources.
    static var lifecycleParticipants: [LifecycleParticipant.Type] {
        var participants: [LifecycleParticipant.Type] = []
        uniqueManifests.forEach { manifest in
            participants += manifest.lifecycleParticipants
        }
        return participants
    }

    /// All AppDelegate listeners from all sources.
    static var appDelegateListeners: [AppDelegateListener.Type] {
        var listeners: [AppDelegateListener.Type] = []
        uniqueManifests.forEach { manifest in
            listeners += manifest.appDelegateListeners
        }
        return listeners
    }

    /// All SceneDelegate listeners from all sources.
    static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        var listeners: [SceneDelegateListener.Type] = []
        uniqueManifests.forEach { manifest in
            listeners += manifest.sceneDelegateListeners
        }
        return listeners
    }
}

// MARK: - Feature Aggregates

extension AppManifest {

    /// Dashboard feature and all its dependencies.
    static var dashboardFeature: [Manifest.Type] {
        [
            NetworkClientManifest.self,
            DashboardManifest.self,
        ]
    }
}
