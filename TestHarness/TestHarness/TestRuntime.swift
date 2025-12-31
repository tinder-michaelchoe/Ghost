//
//  TestRuntime.swift
//  TestHarness
//
//  Created by mexicanpizza on 12/30/25.
//

import Foundation
import CoreContracts

/// A lightweight test runtime for testing services with mock dependencies.
///
/// Usage:
/// ```swift
/// let runtime = TestRuntime()
/// runtime.registerMock(NetworkRequestPerforming.self) { MockNetworkClient() }
/// runtime.registerMock(SecretsProvider.self) { MockSecretsProvider() }
///
/// let weatherService = try runtime.resolve(WeatherService.self)
/// ```
public final class TestRuntime {

    // MARK: - Properties

    private let container: TestContainer

    // MARK: - Init

    public init() {
        self.container = TestContainer()
    }

    // MARK: - Mock Registration

    /// Register a mock implementation for a service type.
    /// - Parameters:
    ///   - type: The service protocol type to mock
    ///   - factory: A closure that creates the mock instance
    public func registerMock<T>(_ type: T.Type, factory: @escaping () -> T) {
        container.register(type) { factory() }
    }

    /// Register a mock instance directly for a service type.
    /// - Parameters:
    ///   - type: The service protocol type to mock
    ///   - mock: The mock instance to return when resolved
    public func registerMock<T>(_ type: T.Type, mock: T) {
        container.register(type) { mock }
    }

    // MARK: - Service Registration

    /// Register a real service provider for testing.
    /// Use this to register the service under test.
    /// - Parameter provider: The service provider to register
    public func register(provider: ServiceProvider) {
        provider.registerServices(container)
    }

    // MARK: - Resolution

    /// Resolve a service, validating all dependencies first.
    /// - Parameter type: The service type to resolve
    /// - Returns: The resolved service instance
    /// - Throws: `TestRuntimeError` if dependencies are missing or there are cycles
    public func resolve<T>(_ type: T.Type) throws -> T {
        let errors = container.validate()
        if !errors.isEmpty {
            throw TestRuntimeError.validationFailed(errors: errors)
        }

        guard let resolved = container.resolve(type) else {
            throw TestRuntimeError.serviceNotRegistered(type: String(describing: type))
        }

        return resolved
    }

    /// Resolve a service without validation (use when you're confident dependencies are set up).
    /// - Parameter type: The service type to resolve
    /// - Returns: The resolved service instance, or nil if not found
    public func resolveUnchecked<T>(_ type: T.Type) -> T? {
        return container.resolve(type)
    }

    // MARK: - Validation

    /// Validate all registered services and their dependencies.
    /// - Returns: Array of validation errors (empty if valid)
    public func validate() -> [ServiceValidationError] {
        container.validate()
    }
}

// MARK: - Test Container

/// A lightweight service container for testing.
/// Implements the same protocols as the production ServiceContainer.
private final class TestContainer: ServiceContainerType {

    private var factories: [String: () -> Any] = [:]
    private var instances: [String: Any] = [:]

    /// Tracks registered services and their declared dependencies
    private var registeredServices: Set<String> = []
    private var declaredDependencies: [String: [String]] = [:]

    // MARK: - ServiceRegistry

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        registeredServices.insert(key)
        factories[key] = { factory() }
    }

    func register<T, each D>(
        _ type: T.Type,
        dependencies: (repeat (each D).Type),
        factory: @escaping (repeat each D) -> T
    ) {
        let key = String(describing: type)
        registeredServices.insert(key)

        // Collect dependency keys
        var depKeys: [String] = []
        repeat depKeys.append(String(describing: each dependencies))
        declaredDependencies[key] = depKeys

        // Store factory that resolves dependencies
        factories[key] = { [weak self] in
            guard let self = self else { fatalError("TestContainer deallocated") }

            let resolved: (repeat each D) = (repeat self.resolve((each D).self)!)
            return factory(repeat each resolved)
        }
    }

    // MARK: - ServiceResolver

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        if let cached = instances[key] as? T {
            return cached
        }

        guard let factory = factories[key] else {
            return nil
        }

        let instance = factory() as? T
        if let instance = instance {
            instances[key] = instance
        }
        return instance
    }

    // MARK: - ServiceValidating

    func validate() -> [ServiceValidationError] {
        var errors: [ServiceValidationError] = []

        for (service, deps) in declaredDependencies {
            for dep in deps {
                if !registeredServices.contains(dep) {
                    errors.append(.missingDependency(service: service, missing: dep))
                }
            }
        }

        return errors
    }
}

// MARK: - Test Runtime Error

/// Errors that can occur when using TestRuntime.
public enum TestRuntimeError: Error, CustomStringConvertible {

    case validationFailed(errors: [ServiceValidationError])
    case serviceNotRegistered(type: String)

    public var description: String {
        switch self {
        case .validationFailed(let errors):
            let errorList = errors.map { "  • \($0.description)" }.joined(separator: "\n")
            return """
                TestRuntime validation failed:
                \(errorList)

                Did you forget to register a mock dependency?
                """

        case .serviceNotRegistered(let type):
            return """
                Service '\(type)' is not registered.

                Make sure to register it using:
                  runtime.register(provider: YourServiceProvider())
                or:
                  runtime.registerMock(\(type).self) { YourMock() }
                """
        }
    }
}
