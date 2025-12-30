//
//  DashboardUIProvider.swift
//  Dashboard
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import Foundation
import SwiftUI

/// Contribution for the home tab that provides a SwiftUI view with tab bar metadata.
struct HomeTabContribution: UIKitViewContribution, TabBarItemProviding {
    let id: ViewContributionID
    let tabBarTitle: String?
    let tabBarIconSystemName: String?

    init(
        id: ViewContributionID = ViewContributionID(rawValue: "dashboard-tab-item"),
        title: String? = "Dashboard",
        iconSystemName: String? = "square.grid.3x3.fill"
    ) {
        self.id = id
        self.tabBarTitle = title
        self.tabBarIconSystemName = iconSystemName
    }

    func makeViewController(context: AppContext) -> AnyViewController {
        return AnyViewController {
            DashboardViewController(context: context)
        }
    }
}

/// UI provider that contributes a TabBarController to the mainView surface.
public final class DashboardUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistryContributing) async {
        let contribution = HomeTabContribution()
        registry.contribute(to: TabBarUISurface.dashboard, item: contribution)
    }
}
