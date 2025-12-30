//
//  ServiceContainer.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation
import CoreContracts

/// Unified thread-safe service container that stores factories, instances, and AppContext.
/// Uses NSRecursiveLock for thread safety to allow nested resolution (e.g., service A depending on service B).
/// Implements ServiceRegistry and ServiceResolver protocols.
public final class ServiceContainer: ServiceContainerType {
    private let lock = NSRecursiveLock()
    private var factories: [String: (AppContext) -> Any] = [:]
    private var instances: [String: Any] = [:]
    private var appContext: AppContext?

    public init() {}

    /// Set the AppContext for service resolution.
    /// Must be called after services are registered and context is created.
    /// - Parameter context: The app context to use for service resolution
    public func setContext(_ context: AppContext) {
        lock.lock()
        defer { lock.unlock() }
        self.appContext = context
    }

    // MARK: - ServiceRegistry

    /// Register a service factory (synchronous).
    /// - Parameters:
    ///   - type: The service type to register
    ///   - factory: The factory closure that creates the service instance
    public func register<T>(_ type: T.Type, factory: @escaping (AppContext) -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        factories[key] = { factory($0) }
    }

    // MARK: - ServiceResolver

    /// Resolve a service by type (synchronous).
    /// Uses the stored AppContext for service creation.
    /// - Parameter type: The service type to resolve
    /// - Returns: The resolved service instance, or nil if not found or context not set
    public func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let context = appContext else {
            return nil
        }
        return resolveUnlocked(type, context: context)
    }

    /// Resolve a service by type with explicit context (internal).
    /// Assumes lock is already held.
    /// - Parameters:
    ///   - type: The service type to resolve
    ///   - context: The app context to use for service creation
    /// - Returns: The resolved service instance, or nil if not found
    private func resolveUnlocked<T>(_ type: T.Type, context: AppContext) -> T? {
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
