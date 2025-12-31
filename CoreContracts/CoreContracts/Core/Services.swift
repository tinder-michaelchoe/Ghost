//
//  type.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation

public typealias ServiceContainerType = ServiceRegistry & ServiceResolver & ServiceValidating

/// Registers services by protocol type with explicit dependencies.
public protocol ServiceRegistry {
    /// Register a service with no dependencies.
    func register<T>(_ type: T.Type, factory: @escaping () -> T)

    /// Register a service with explicit dependencies using parameter packs.
    /// Dependencies are resolved and passed to the factory.
    func register<T, each D>(
        _ type: T.Type,
        dependencies: (repeat (each D).Type),
        factory: @escaping (repeat each D) -> T
    )
}

/// Resolves services by protocol type.
public protocol ServiceResolver {
    func resolve<T>(_ type: T.Type) -> T?
}

/// Validates the service dependency graph.
public protocol ServiceValidating {
    /// Validates that all dependencies form a valid DAG (no cycles, all dependencies registered).
    /// Returns validation errors if any issues are found.
    func validate() -> [ServiceValidationError]
}

/// Errors that can occur during service graph validation.
public enum ServiceValidationError: Error, Equatable, CustomStringConvertible {
    case cyclicDependency(service: String, cycle: [String])
    case missingDependency(service: String, missing: String)

    public var description: String {
        switch self {
        case .cyclicDependency(let service, let cycle):
            return "Cyclic dependency detected for '\(service)': \(cycle.joined(separator: " -> "))"
        case .missingDependency(let service, let missing):
            return "Service '\(service)' depends on '\(missing)' which is not registered"
        }
    }
}
