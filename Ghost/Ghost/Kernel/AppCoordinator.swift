//
//  AppCoordinator.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation
import CoreContracts

/// Orchestrates app initialization and provides runtime access to managers.
/// Handles the initialization sequence and exposes managers for runtime operations.
final class AppCoordinator {
    let serviceManager: ServiceManager
    let uiManager: UIManager
    let lifecycleManager: LifecycleManager

    init(serviceManager: ServiceManager) {
        self.serviceManager = serviceManager
        self.uiManager = UIManager()
        self.lifecycleManager = LifecycleManager()
    }

    /// Initialize the app with providers from the manifest.
    /// Orchestrates the initialization sequence: services → UI → lifecycle.
    /// - Parameter manifest: The manifest containing all providers
    /// - Throws: AppError if initialization fails
    func initialize(manifest: Manifest.Type) async throws {
        // Step 1: Register services
        try serviceManager.register(providers: manifest.serviceProviders)

        // Step 2: Set service resolver for UI contribution dependency injection
        uiManager.setServiceResolver(serviceManager.serviceContainer)

        // Step 3: Register UI providers
        try await uiManager.register(providers: manifest.uiProviders)

        // Step 4: Register lifecycle participants
        lifecycleManager.register(participants: manifest.lifecycleParticipants)
    }

    /// Run all lifecycle participants through a lifecycle phase.
    /// - Parameter phase: The lifecycle phase to execute
    func runPhase(_ phase: LifecyclePhase) async {
        await lifecycleManager.runPhase(phase)
    }
}

