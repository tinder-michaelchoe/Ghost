//
//  StaticExamplesUIProvider.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/24/25.
//

import Foundation
import CoreContracts
import SwiftUI

// MARK: - Clads Examples UI Provider

/// UI provider that contributes the static examples view to the home tab.
/// Injects WeatherService for the weather dashboard example.
public final class CladsExamplesUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(
            to: TabBarUISurface.home,
            contribution: TabBarContribution(
                title: "CLADS",
                normalIcon: "scribble.variable",
                selectedIcon: nil
            ),
            dependencies: (WeatherService.self),
            factory: { weatherService in
                CladsExamplesView(weatherService: weatherService)
            }
        )
    }
}

// MARK: - Tab Bar Contribution

private struct TabBarContribution: ViewContribution, TabBarItemProviding, Sendable {
    let id: ViewContributionID
    let tabBarTitle: String?
    let tabBarIconSystemName: String?

    init(
        title: String,
        normalIcon: String,
        selectedIcon: String?
    ) {
        self.id = ViewContributionID(rawValue: title)
        self.tabBarTitle = title
        self.tabBarIconSystemName = normalIcon
    }
}
