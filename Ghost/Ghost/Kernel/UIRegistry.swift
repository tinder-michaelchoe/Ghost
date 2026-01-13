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
    
    /// Tracks contribution metadata for logging
    private var contributionMetadata: [(surface: String, contributionId: String, dependencies: [String])] = []

    init() {
        log("🏗️ UIRegistry initialized")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[UIRegistry] [\(timestamp)] \(message)")
    }

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
        let surfaceName = String(describing: surface)
        let contributionId = contribution.id.rawValue
        log("🎨 Contributing UIKit view: \(contributionId) → surface: \(surfaceName) (no dependencies)")
        
        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: { AnyViewController { factory() } }
        )
        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
            contributionMetadata.append((surface: surfaceName, contributionId: contributionId, dependencies: []))
        }
    }

    // MARK: - Registration (No Dependencies) - SwiftUI

    func contribute<S: UISurface, C: ViewContribution, V: View>(
        to surface: S,
        contribution: C,
        @ViewBuilder factory: @escaping @MainActor @Sendable () -> V
    ) {
        let surfaceName = String(describing: surface)
        let contributionId = contribution.id.rawValue
        log("🎨 Contributing SwiftUI view: \(contributionId) → surface: \(surfaceName) (no dependencies)")
        
        let resolved = ResolvedContribution(
            contribution: contribution,
            viewFactory: {
                AnyViewController { UIHostingController(rootView: AnyView(factory())) }
            }
        )
        queue.sync {
            resolvedContributions[AnyHashable(surface), default: []].append(resolved)
            contributionMetadata.append((surface: surfaceName, contributionId: contributionId, dependencies: []))
        }
    }

    // MARK: - Registration (With Dependencies) - UIKit

    func contribute<S: UISurface, C: ViewContribution, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        factory: @escaping @MainActor @Sendable (repeat each D) -> UIViewController
    ) {
        let surfaceName = String(describing: surface)
        let contributionId = contribution.id.rawValue
        var depNames: [String] = []
        repeat depNames.append(String(describing: each dependencies))
        log("🎨 Contributing UIKit view: \(contributionId) → surface: \(surfaceName) → deps: [\(depNames.joined(separator: ", "))]")
        
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
            contributionMetadata.append((surface: surfaceName, contributionId: contributionId, dependencies: depNames))
        }
    }

    // MARK: - Registration (With Dependencies) - SwiftUI

    func contribute<S: UISurface, C: ViewContribution, V: View, each D>(
        to surface: S,
        contribution: C,
        dependencies: (repeat (each D).Type),
        @ViewBuilder factory: @escaping @MainActor @Sendable (repeat each D) -> V
    ) {
        let surfaceName = String(describing: surface)
        let contributionId = contribution.id.rawValue
        var depNames: [String] = []
        repeat depNames.append(String(describing: each dependencies))
        log("🎨 Contributing SwiftUI view: \(contributionId) → surface: \(surfaceName) → deps: [\(depNames.joined(separator: ", "))]")
        
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
            contributionMetadata.append((surface: surfaceName, contributionId: contributionId, dependencies: depNames))
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
    
    /// Dumps all registered UI contributions for debugging.
    /// Shows the complete contribution list from this centralized orchestrator.
    func dumpContributions() {
        queue.sync {
            print("")
            print("╔══════════════════════════════════════════════════════════════════╗")
            print("║              UI REGISTRY - REGISTERED CONTRIBUTIONS              ║")
            print("╠══════════════════════════════════════════════════════════════════╣")
            print("║ Total Contributions: \(contributionMetadata.count.description.padding(toLength: 44, withPad: " ", startingAt: 0))║")
            print("╠══════════════════════════════════════════════════════════════════╣")
            
            // Group by surface
            let grouped = Dictionary(grouping: contributionMetadata, by: { $0.surface })
            let sortedSurfaces = grouped.keys.sorted()
            
            for surface in sortedSurfaces {
                print("║ 📱 Surface: \(surface.padding(toLength: 53, withPad: " ", startingAt: 0))║")
                
                let contributions = grouped[surface] ?? []
                for (index, contrib) in contributions.enumerated() {
                    let isLast = index == contributions.count - 1
                    let prefix = isLast ? "└──" : "├──"
                    print("║    \(prefix) \(contrib.contributionId.padding(toLength: 57, withPad: " ", startingAt: 0))║")
                    
                    if !contrib.dependencies.isEmpty {
                        for (depIndex, dep) in contrib.dependencies.enumerated() {
                            let depIsLast = depIndex == contrib.dependencies.count - 1
                            let depPrefix = depIsLast ? "└──" : "├──"
                            let indent = isLast ? "    " : "│   "
                            print("║    \(indent)   \(depPrefix) → \(dep.padding(toLength: 49, withPad: " ", startingAt: 0))║")
                        }
                    }
                }
                print("║                                                                  ║")
            }
            
            print("╚══════════════════════════════════════════════════════════════════╝")
            print("")
        }
    }
}

extension UIRegistry: TabBarUIContributing {}
