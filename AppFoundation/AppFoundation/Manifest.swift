//
//  AppFoundation+ModuleProvider.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

/// Provider that vends all modules available from AppFoundation.
/// This is the single entry point for discovering AppFoundation modules.
public enum AppFoundationModules: Manifest {
    /// Returns all service providers from AppFoundation.
    public static var serviceProviders: [ServiceProvider.Type] {
        [
            LoggingServiceProvider.self,
            AnalyticsServiceProvider.self
        ]
    }
    
    /// Returns all UI providers from AppFoundation.
    public static var uiProviders: [UIProvider.Type] {
        []
    }
    
    /// Returns all lifecycle participants from AppFoundation.
    public static var lifecycleParticipants: [LifecycleParticipant.Type] {
        [
            LoggingServiceProvider.self,
            AnalyticsServiceProvider.self
        ]
    }
}

