//
//  PersistenceManifest.swift
//  Persistence
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts

/// Manifest for the Persistence module.
/// Provides PersistenceService for app-wide data persistence.
public enum PersistenceManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [PersistenceServiceProvider.self]
    }
}
