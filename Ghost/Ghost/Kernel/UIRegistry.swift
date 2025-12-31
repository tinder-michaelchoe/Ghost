//
//  UIRegistryImpl.swift
//  Ghost
//
//  Created by mexicanpizza on 12/22/25.
//

import Foundation
import CoreContracts
import SwiftUI
import UIKit

/// Thread-safe storage for UI contributions.
/// Uses a serial DispatchQueue for thread safety, providing synchronous interface.
final class UIRegistry: UIRegistryContributing, UIRegistryValidating, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.ghost.uiregistry")
    private var resolvedContributions: [AnyHashable: [ResolvedContribution]] = [:]

    /// Service resolver for dependency injection
    private var serviceResolver: ServiceResolver?

    /// Pending validations (contribution ID -> dependency types)
    private var pendingValidations: [(contributionId: String, dependencyType: Any.Type)] = []

    init() {}

    /// Set the service resolver for dependency resolution.
    /// Must be called before contributions with dependencies are registered.
    func setServiceResolver(_ resolver: ServiceResolver) {
        queue.sync {
            self.serviceResolver = resolver
        }
    }

    // MARK: - UIRegistryContributing

    /// Get all resolved contributions for a UI surface.
    func contributions<T: UISurface>(for surface: T) -> [ResolvedContribution] {
        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []]
        }
    }

    // MARK: - Registration (No Dependencies) - UIKit

    func contribute<S: UISurface, C: ViewContribution>(
        to surface: S,
        contribution: C,
        factory: @escaping @MainActor @Sendable () -> UIViewController
    ) {
        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: { AnyViewController { factory() } }
        )
        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
        }
    }

    // MARK: - Registration (No Dependencies) - SwiftUI

    func contribute<S: UISurface, C: ViewContribution, V: View>(
        to surface: S,
        contribution: C,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    ) {
        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: {
                AnyViewController { UIHostingController(rootView: AnyView(factory())) }
            }
        )
        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
        }
    }

    // MARK: - Registration (With Dependencies) - UIKit

    func contribute<S: UISurface, C: ViewContribution, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        factory: @escaping @MainActor @Sendable (repeat each D) -> UIViewController
    ) {
        // Record pending validations
        queue.sync {
            repeat pendingValidations.append((contribution.id.rawValue, (each D).self))
        }

        // Create a factory that resolves dependencies at call time
        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: { [weak self] in
                guard let self, let resolver = self.serviceResolver else {
                    fatalError("UIRegistry: ServiceResolver not set")
                }
                let deps: (repeat each D) = (repeat resolver.resolve((each D).self)!)
                return AnyViewController { factory(repeat each deps) }
            }
        )

        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
        }
    }

    // MARK: - Registration (With Dependencies) - SwiftUI

    func contribute<S: UISurface, C: ViewContribution, V: View, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        @ViewBuilder factory: @escaping @MainActor @Sendable (repeat each D) -> V
    ) {
        // Record pending validations
        queue.sync {
            repeat pendingValidations.append((contribution.id.rawValue, (each D).self))
        }

        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: { [weak self] in
                guard let self, let resolver = self.serviceResolver else {
                    fatalError("UIRegistry: ServiceResolver not set")
                }
                let deps: (repeat each D) = (repeat resolver.resolve((each D).self)!)
                return AnyViewController { UIHostingController(rootView: AnyView(factory(repeat each deps))) }
            }
        )

        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
        }
    }

    // MARK: - UIRegistryValidating

    func validate(against resolver: ServiceResolver) -> [UIContributionValidationError] {
        queue.sync {
            // Note: With parameter packs, we can't easily check if a type is registered
            // at runtime without using reflection. For now, validation happens at
            // view creation time (the factory will crash if dependency is missing).
            // A proper implementation would track registered service types.
            []
        }
    }

    // MARK: - Debug

    /// Get all contributions across all surfaces (for debugging).
    func allContributions() -> [AnyHashable: [ResolvedContribution]] {
        queue.sync {
            resolvedContributions
        }
    }
}

extension UIRegistry: TabBarUIContributing {}
