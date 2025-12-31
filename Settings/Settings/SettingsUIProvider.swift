//
//  SettingsUIProvider.swift
//  Settings
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts
import SwiftUI

// MARK: - Settings Tab Contribution

struct SettingsTabContribution: ViewContribution, TabBarItemProviding, Sendable {
    let id = ViewContributionID(rawValue: "settings-tab-item")
    let tabBarTitle: String? = "Settings"
    let tabBarIconSystemName: String? = "gear"
}

// MARK: - Settings UI Provider

/// UI provider that contributes the settings tab.
public final class SettingsUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        registry.contribute(to: TabBarUISurface.settings, contribution: SettingsTabContribution()) {
            SettingsView()
        }
    }
}
