//
//  UIRegistryImpl.swift
//  Ghost
//
//  Created by mexicanpizza on 12/22/25.
//

import Foundation
import CoreContracts

/// Thread-safe storage for UI contributions.
actor UIRegistry {
    private var contributions: [AnyHashable: [any ViewContribution]] = [:]
    
    func contribute<T: UISurface>(to surface: T, item: any ViewContribution) {
        contributions[AnyHashable(surface), default: []].append(item)
    }
    
    func getContributions<T: UISurface>(for surface: T) -> [any ViewContribution] {
        contributions[AnyHashable(surface), default: []]
    }
    
    func getAllContributions() -> [AnyHashable: [any ViewContribution]] {
        contributions
    }
}

/// Implementation of UIRegistry protocol that collects UI contributions.
final class UIRegistryImpl: CoreContracts.UIRegistry {
    private let registry: UIRegistry
    
    init() {
        self.registry = UIRegistry()
    }
    
    func contribute<T: UISurface>(to surface: T, item: some ViewContribution) {
        Task {
            await registry.contribute(to: surface, item: item)
        }
    }
    
    /// Async version for use during initialization
    func contributeAsync<T: UISurface>(to surface: T, item: some ViewContribution) async {
        await registry.contribute(to: surface, item: item)
    }
    
    func getContributions<T: UISurface>(for surface: T) async -> [any ViewContribution] {
        await registry.getContributions(for: surface)
    }
    
    func getAllContributions() async -> [AnyHashable: [any ViewContribution]] {
        await registry.getAllContributions()
    }
}

// Make UIRegistryImpl conform to UIRegistryContributions for TabBarController
extension UIRegistryImpl: UIRegistryContributions {}
