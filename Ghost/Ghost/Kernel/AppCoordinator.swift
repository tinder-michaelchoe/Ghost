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
    private(set) var context: AppContext?
    
    init(serviceManager: ServiceManager) {
        self.serviceManager = serviceManager
        self.uiManager = UIManager()
        self.lifecycleManager = LifecycleManager()
    }
    
    /// Initialize the app with providers from the manifest.
    /// Orchestrates the initialization sequence: services → context → UI → lifecycle.
    /// - Parameter manifest: The manifest containing all providers
    /// - Returns: The created AppContext
    /// - Throws: AppError if initialization fails
    func initialize(manifest: Manifest.Type) async throws -> AppContext {
        
        // Step 1: Register remaining services (excluding bootstrap services which are already registered)
        try serviceManager.register(providers: manifest.serviceProviders)
        
        // Step 2: Create AppContext after services are registered
        let config = AppConfig(
            buildInfo: BuildInfo(appVersion: "1.0", buildNumber: "1")
        )
        
        // Step 3: Create AppContext with the service container as the resolver
        // Note: uiRegistry is passed here but UI providers are registered later.
        // The registry will be populated when UI providers register their contributions.
        context = AppContext(
            services: serviceManager.serviceContainer,
            config: config,
            uiRegistry: uiManager.uiRegistry
        )
        
        guard let context = context else {
            throw AppError.contextCreationFailed
        }
        
        // Step 4: Set context in service manager for resolution
        // This must be done after AppContext is created (circular dependency)
        serviceManager.setContext(context)
        
        // Step 5: Register UI providers (can now use services via context)
        try await uiManager.register(providers: manifest.uiProviders)
        
        // Step 6: Register lifecycle participants
        lifecycleManager.register(participants: manifest.lifecycleParticipants)
        
        return context
    }
    
    /// Run all lifecycle participants through a lifecycle phase.
    /// - Parameter phase: The lifecycle phase to execute
    func runPhase(_ phase: LifecyclePhase) async {
        guard let context = context else {
            print("⚠️ No context available for phase \(phase)")
            return
        }
        await lifecycleManager.runPhase(phase, context: context)
    }
}

enum AppError: Error {
    case contextCreationFailed
}

