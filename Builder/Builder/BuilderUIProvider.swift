//
//  BuilderUIProvider.swift
//  Builder
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts
import UIKit

// MARK: - Builder Tab Contribution

struct BuilderTabContribution: ViewContribution, TabBarItemProviding, Sendable {
    let id = ViewContributionID(rawValue: "builder-tab-item")
    let tabBarTitle: String? = "Builder"
    let tabBarIconSystemName: String? = "batteryblock"
}

// MARK: - Builder UI Provider

/// UI provider that contributes the builder tab.
public final class BuilderUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(
            to: TabBarUISurface.builder,
            contribution: BuilderTabContribution()
        ) {
            BuilderViewController(nibName: nil, bundle: nil)
        }
    }
}
