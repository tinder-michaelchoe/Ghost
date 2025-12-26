//
//  BootstrapCoordinator.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import CoreContracts
import Foundation
import UIKit

/// Coordinates bootstrap service registration and provides ServiceManager to AppCoordinator.
/// Runs synchronously during app launch to register critical services before other initialization.
final class BootstrapCoordinator {
    
    /// The ServiceManager with bootstrap services registered.
    /// This will be provided to AppCoordinator during scene connection.
    private(set) var serviceManager: ServiceManager?
    
    /// Whether bootstrap services have been registered.
    private var bootstrapServicesRegistered = false
    
    init() {
        // Create ServiceManager for bootstrap services
        self.serviceManager = ServiceManager()
    }
    
    /// Register bootstrap services synchronously.
    /// This must be called during didFinishLaunchingWithOptions (synchronous context).
    /// - Parameter providers: Array of bootstrap service provider types to register
    func registerBootstrapServices(providers: [ServiceProvider.Type]) {
        guard !bootstrapServicesRegistered else {
            print("⚠️ BootstrapCoordinator: Bootstrap services already registered")
            return
        }
        
        guard let serviceManager = serviceManager else {
            print("❌ BootstrapCoordinator: ServiceManager not available")
            return
        }
        
        guard !providers.isEmpty else {
            print("ℹ️ BootstrapCoordinator: No bootstrap service providers to register")
            bootstrapServicesRegistered = true
            return
        }
        
        // Register services synchronously (no async needed)
        do {
            try serviceManager.register(providers: providers)
            bootstrapServicesRegistered = true
            print("✅ BootstrapCoordinator: Registered \(providers.count) bootstrap service providers")
        } catch {
            print("❌ BootstrapCoordinator: Failed to register bootstrap services: \(error)")
        }
    }
}
