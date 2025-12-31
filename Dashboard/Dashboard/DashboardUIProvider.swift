//
//  DashboardUIProvider.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import UIKit

// MARK: - Dashboard UI Provider

/// UI provider that contributes the dashboard tab.
public final class DashboardUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistryContributing) {
        guard let registry = registry as? TabBarUIContributing else { return }
        registry.contribute(
            to: .dashboard,
            title: "Dashboard",
            normalIcon: "square.grid.3x3.fill",
            selectedIcon: nil,
            factory: {
                DashboardViewController(uiRegistry: registry)
            }
        )
    }
}
