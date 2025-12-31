//
//  ServiceManager.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation
import CoreContracts

/// Manages service registration and resolution.
/// Handles ServiceProvider registration and provides service resolution.
public final class ServiceManager: ServiceManagerProtocol {
    private let container: ServiceContainer
    private var providers: [ServiceProvider] = []
    
    public init() {
        self.container = ServiceContainer()
    }
    
    /// Get the service container (exposed as protocol type).
    public var serviceContainer: ServiceContainerType {
        container
    }
    
    /// Register service providers.
    /// - Parameter providers: Array of ServiceProvider types to register
    public func register(providers: [ServiceProvider.Type]) throws {
        for providerType in providers {
            let instance = providerType.init()
            self.providers.append(instance)
            // Register services using the container (synchronous)
            instance.registerServices(container)
        }
    }
    
    /// Resolve a service by type.
    /// - Parameter type: The service type to resolve
    /// - Returns: The resolved service instance, or nil if not found
    public func resolve<T>(_ type: T.Type) -> T? {
        container.resolve(type)
    }
}

