//
//  ServiceContainer.swift
//  Ghost
//
//  Created by mexicanpizza on 12/22/25.
//

import Foundation
import CoreContracts

/// Thread-safe storage for service factories and instances.
actor ServiceContainer {
    private var factories: [String: (AppContext) -> Any] = [:]
    private var instances: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping (AppContext) -> T) {
        let key = String(describing: type)
        factories[key] = { factory($0) }
    }
    
    /// Resolve a service with context (used internally by kernel)
    func resolve<T>(_ type: T.Type, context: AppContext) -> T? {
        let key = String(describing: type)
        
        // Check for cached instance
        if let cached = instances[key] as? T {
            return cached
        }
        
        // Create new instance using factory
        guard let factory = factories[key] else {
            return nil
        }
        
        let instance = factory(context) as? T
        if let instance = instance {
            instances[key] = instance
        }
        return instance
    }
}

/// Thread-safe wrapper for ServiceContainer that implements ServiceRegistry and ServiceResolver
final class ServiceContainerWrapper: ServiceRegistry, ServiceResolver {
    private let container: ServiceContainer
    private var contextForResolution: AppContext?
    
    init() {
        self.container = ServiceContainer()
    }
    
    func setContext(_ context: AppContext) {
        self.contextForResolution = context
    }
    
    func register<T>(_ type: T.Type, factory: @escaping (AppContext) -> T) {
        Task {
            await container.register(type, factory: factory)
        }
    }
    
    /// Async version for use during initialization
    func registerAsync<T>(_ type: T.Type, factory: @escaping (AppContext) -> T) async {
        await container.register(type, factory: factory)
    }
    
    func resolve<T>(_ type: T.Type) async -> T? {
        // Synchronous resolution - use cached context
        guard let context = await contextForResolution else {
            return nil
        }
        let result = await container.resolve(type, context: context)
        return result
        /*
        // Use continuation to bridge async/sync boundary
        return withCheckedContinuation { continuation in
            Task {
                let result = await container.resolve(type, context: context)
                continuation.resume(returning: result)
            }
        }
         */
    }
    
    /// Resolve a service with context (used internally by kernel)
    func resolve<T>(_ type: T.Type, context: AppContext) async -> T? {
        await container.resolve(type, context: context)
    }
}

