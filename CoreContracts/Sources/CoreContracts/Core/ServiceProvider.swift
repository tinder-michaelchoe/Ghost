//
//  ServiceProvider.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for modules that provide services.
/// Conform to this if your module registers services in the service container.
public protocol ServiceProvider {
    init()
    /// Register services provided by this module.
    func registerServices(_ registry: ServiceRegistry)
}

