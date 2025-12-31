//
//  UIRegistry.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

import UIKit
import SwiftUI

// MARK: - UI Registry Contributing

/// Registry for UI contributions.
/// Provides methods for registering UI contributions with explicit dependencies.
/// The view type (UIKit or SwiftUI) is inferred from the factory return type.
public protocol UIRegistryContributing: Sendable {

    // MARK: - Query

    /// Get all resolved contributions for a UI surface.
    /// - Parameter surface: The UI surface to get contributions for
    /// - Returns: Array of resolved contributions for the surface
    func contributions<T: UISurface>(for surface: T) -> [ResolvedContribution]

    // MARK: - Registration (No Dependencies) - UIKit

    /// Register a UIKit contribution with no dependencies.
    func contribute<S: UISurface, C: ViewContribution>(
        to surface: S,
        contribution: C,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    )

    // MARK: - Registration (No Dependencies) - SwiftUI

    /// Register a SwiftUI contribution with no dependencies.
    /// Uses @ViewBuilder to allow natural SwiftUI syntax without AnyView wrapping.
    func contribute<S: UISurface, C: ViewContribution, V: View>(
        to surface: S,
        contribution: C,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    )

    // MARK: - Registration (With Dependencies) - UIKit

    /// Register a UIKit contribution with dependencies.
    /// Dependencies are resolved from the service container at view creation time.
    func contribute<S: UISurface, C: ViewContribution, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        factory: @escaping @MainActor @Sendable (repeat each D) -> UIViewController
    )

    // MARK: - Registration (With Dependencies) - SwiftUI

    /// Register a SwiftUI contribution with dependencies.
    /// Dependencies are resolved from the service container at view creation time.
    /// Uses @ViewBuilder to allow natural SwiftUI syntax without AnyView wrapping.
    func contribute<S: UISurface, C: ViewContribution, V: View, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        @ViewBuilder factory: @escaping @MainActor @Sendable (repeat each D) -> V
    )
}

// MARK: - Convenience Methods (Inline Contributions)

public extension UIRegistryContributing {

    // MARK: - UIKit Inline

    /// Register a UIKit contribution with just an ID (no custom metadata).
    func contribute<S: UISurface>(
        to surface: S,
        id: String,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    ) {
        contribute(to: surface, contribution: InlineContribution(id: id), factory: factory)
    }

    // MARK: - SwiftUI Inline

    /// Register a SwiftUI contribution with just an ID (no custom metadata).
    func contribute<S: UISurface, V: View>(
        to surface: S,
        id: String,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    ) {
        contribute(to: surface, contribution: InlineContribution(id: id), factory: factory)
    }
}

// MARK: - UI Registry Validating

/// Protocol for validating UI contributions against available services.
public protocol UIRegistryValidating {
    /// Validate that all contribution dependencies can be resolved.
    /// - Parameter resolver: The service resolver to validate against
    /// - Returns: Array of validation errors (empty if valid)
    func validate(against resolver: ServiceResolver) -> [UIContributionValidationError]
}

// MARK: - UI Contribution Validation Error

/// Errors that can occur when validating UI contributions.
public enum UIContributionValidationError: Error, CustomStringConvertible, Sendable {
    case missingDependency(contribution: String, missing: String)

    public var description: String {
        switch self {
        case .missingDependency(let contribution, let missing):
            return "Contribution '\(contribution)' requires '\(missing)' but it is not registered"
        }
    }
}
