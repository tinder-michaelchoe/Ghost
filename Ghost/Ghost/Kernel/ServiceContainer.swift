//
//  ServiceContainer.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import AppFoundation
import Foundation
import CoreContracts

/// Unified thread-safe service container that stores factories, instances, and AppContext.
/// Uses NSRecursiveLock for thread safety to allow nested resolution (e.g., service A depending on service B).
/// Implements ServiceRegistry, ServiceResolver, and ServiceValidating protocols.
public final class ServiceContainer: ServiceContainerType {
    private let lock = NSRecursiveLock()
    private var factories: [String: (AppContext) -> Any] = [:]
    private var instances: [String: Any] = [:]
    private var appContext: AppContext?

    /// Dependency graph: service type -> [dependency types]
    private var dependencyGraph: DAG<String> = DAG()

    /// Tracks which services have been registered (for validation)
    private var registeredServices: Set<String> = []

    /// Stores the declared dependencies for each service (for validation)
    private var declaredDependencies: [String: [String]] = [:]

    /// Stores edges that were rejected due to cycle detection (service -> dependency that would cause cycle)
    private var rejectedCyclicEdges: [(service: String, dependency: String)] = []

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

    /// Register a service factory without explicit dependencies (legacy).
    /// - Parameters:
    ///   - type: The service type to register
    ///   - factory: The factory closure that creates the service instance
    public func register<T>(_ type: T.Type, factory: @escaping (AppContext) -> T) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        registeredServices.insert(key)
        dependencyGraph.addNode(key)
        factories[key] = { factory($0) }
    }

    /// Register a service with explicit dependencies using parameter packs.
    /// Dependencies are resolved and passed to the factory along with ServiceContext.
    /// - Parameters:
    ///   - type: The service type to register
    ///   - dependencies: A tuple of dependency types that this service requires
    ///   - factory: The factory closure that receives ServiceContext and resolved dependencies
    public func register<T, each D>(
        _ type: T.Type,
        dependencies: (repeat (each D).Type),
        factory: @escaping (ServiceContext, repeat each D) -> T
    ) {
        lock.lock()
        defer { lock.unlock() }

        let key = String(describing: type)
        registeredServices.insert(key)
        dependencyGraph.addNode(key)

        // Collect dependency keys and add edges to the graph
        var depKeys: [String] = []
        repeat depKeys.append(String(describing: each dependencies))
        declaredDependencies[key] = depKeys

        for depKey in depKeys {
            dependencyGraph.addNode(depKey)
            let edgeAdded = dependencyGraph.addEdge(from: key, to: depKey)
            if !edgeAdded {
                // Edge was rejected because it would create a cycle
                rejectedCyclicEdges.append((service: key, dependency: depKey))
            }
        }

        // Store factory that resolves dependencies and calls the provided factory
        factories[key] = { [weak self] context in
            guard let self = self else { fatalError("ServiceContainer deallocated") }

            let serviceContext = ServiceContext(
                config: context.config,
                uiRegistry: context.uiRegistry
            )

            // Resolve each dependency - force unwrap since validation should catch missing deps
            let resolved: (repeat each D) = (repeat self.resolveUnlocked((each D).self, context: context)!)

            return factory(serviceContext, repeat each resolved)
        }
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
    /// Pre-resolves all dependencies in topological order before creating the service.
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

        // Pre-resolve all dependencies in topological order
        let depsInOrder = topologicallySortedDependencies(for: key)
        for depKey in depsInOrder {
            // Skip if already resolved
            if instances[depKey] != nil { continue }

            // Resolve the dependency (this will cache it)
            if let factory = factories[depKey] {
                instances[depKey] = factory(context)
            }
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

    /// Returns all transitive dependencies of a service in topological order (dependencies before dependents).
    /// Uses Kahn's algorithm for topological sorting.
    /// - Parameter key: The service key to get dependencies for
    /// - Returns: Array of dependency keys in the order they should be resolved
    private func topologicallySortedDependencies(for key: String) -> [String] {
        // First, collect all transitive dependencies
        var allDeps: Set<String> = []
        collectTransitiveDependencies(key, into: &allDeps)

        // If no dependencies, return empty
        if allDeps.isEmpty {
            return []
        }

        // Build a subgraph of just the dependencies and apply Kahn's algorithm
        // In our graph: edge from A -> B means A depends on B
        // For Kahn's, we need in-degree = number of services that depend on this service

        // Calculate in-degree for each dependency (how many other deps point to it)
        var inDegree: [String: Int] = [:]
        for dep in allDeps {
            inDegree[dep] = 0
        }

        // For each dependency, count how many other dependencies depend on it
        for dep in allDeps {
            for child in dependencyGraph.children(of: dep) {
                if allDeps.contains(child) {
                    inDegree[child, default: 0] += 1
                }
            }
        }

        // Kahn's algorithm: start with nodes that have in-degree 0 (no dependents within our subgraph)
        var queue: [String] = []
        for (dep, degree) in inDegree where degree == 0 {
            queue.append(dep)
        }

        var result: [String] = []

        while !queue.isEmpty {
            let current = queue.removeFirst()
            result.append(current)

            // Reduce in-degree for all dependencies of current
            for child in dependencyGraph.children(of: current) {
                if allDeps.contains(child) {
                    inDegree[child, default: 0] -= 1
                    if inDegree[child] == 0 {
                        queue.append(child)
                    }
                }
            }
        }

        // Reverse because we want dependencies (leaves) first, not dependents
        return result.reversed()
    }

    /// Recursively collect all transitive dependencies for a service.
    private func collectTransitiveDependencies(_ key: String, into deps: inout Set<String>) {
        for child in dependencyGraph.children(of: key) {
            if !deps.contains(child) {
                deps.insert(child)
                collectTransitiveDependencies(child, into: &deps)
            }
        }
    }

    // MARK: - ServiceValidating

    /// Validates that all dependencies form a valid DAG (no cycles, all dependencies registered).
    /// Returns validation errors if any issues are found.
    public func validate() -> [ServiceValidationError] {
        lock.lock()
        defer { lock.unlock() }

        var errors: [ServiceValidationError] = []

        // Check for missing dependencies
        for (service, deps) in declaredDependencies {
            for dep in deps {
                if !registeredServices.contains(dep) {
                    errors.append(.missingDependency(service: service, missing: dep))
                }
            }
        }

        // Check for cycles - edges that were rejected during registration
        for (service, dependency) in rejectedCyclicEdges {
            let cycle = buildCyclePath(from: service, to: dependency)
            errors.append(.cyclicDependency(service: service, cycle: cycle))
        }

        return errors
    }

    /// Build the cycle path from service through the existing graph back to service.
    /// The edge service -> dependency was rejected, so dependency can reach service.
    private func buildCyclePath(from service: String, to dependency: String) -> [String] {
        // service wants to depend on dependency, but dependency already reaches service
        // So the cycle is: service -> dependency -> ... -> service
        var path: [String] = [service, dependency]

        // If self-dependency
        if service == dependency {
            return [service, service]
        }

        // Find path from dependency back to service using existing edges
        var current = dependency
        var visited: Set<String> = [service, dependency]

        while current != service {
            let children = dependencyGraph.children(of: current)
            var found = false

            for child in children {
                if child == service {
                    path.append(service)
                    return path
                }
                if !visited.contains(child) && dependencyGraph.canReach(from: child, to: service) {
                    path.append(child)
                    visited.insert(child)
                    current = child
                    found = true
                    break
                }
            }

            if !found { break }
        }

        // Append service to close the cycle if not already there
        if path.last != service {
            path.append(service)
        }

        return path
    }
}
