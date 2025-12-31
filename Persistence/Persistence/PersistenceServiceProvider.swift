//
//  PersistenceServiceProvider.swift
//  Persistence
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import Foundation

// MARK: - Persistence Service Provider

/// Service provider that registers the PersistenceService.
///
/// By default, uses UserDefaults-backed persistence. This can be changed
/// to CoreData, file-based storage, or any other implementation without
/// affecting consumers.
public final class PersistenceServiceProvider: ServiceProvider {

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(PersistenceService.self) {
            UserDefaultsPersistence()
        }
    }
}
