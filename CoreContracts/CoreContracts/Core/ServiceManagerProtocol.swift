//
//  ServiceManagerProtocol.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation

/// Protocol for service managers that can register and resolve services.
/// This allows modules to work with service managers without depending on concrete implementations.
public protocol ServiceManagerProtocol: AnyObject {
    /// Register service providers.
    /// - Parameter providers: Array of ServiceProvider types to register
    func register(providers: [ServiceProvider.Type]) throws

    /// Get the service container.
    var serviceContainer: ServiceContainerType { get }
}

