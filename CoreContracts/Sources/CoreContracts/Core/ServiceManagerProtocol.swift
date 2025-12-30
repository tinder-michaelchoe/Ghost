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
    
    /// Set the context for service resolution.
    /// Must be called after services are registered and context is created.
    func setContext(_ context: AppContext)
    
    /// Get the service container (for use in AppContext).
    var serviceContainer: ServiceContainerType { get }
}

