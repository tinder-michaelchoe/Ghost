//
//  BuilderUIProvider.swift
//  Builder
//
//  Created by mexicanpizza on 12/24/25.
//

import Foundation
import CoreContracts
import SwiftUI

/// Contribution for the home tab that provides a SwiftUI view with tab bar metadata.
struct HomeTabContribution: UIKitViewContribution, TabBarItemProviding {
    let id: ViewContributionID
    let tabBarTitle: String?
    let tabBarIconSystemName: String?
    
    init(
        id: ViewContributionID = ViewContributionID(rawValue: "builder-tab-item"),
        title: String? = "Builder",
        iconSystemName: String? = "batteryblock"
    ) {
        self.id = id
        self.tabBarTitle = title
        self.tabBarIconSystemName = iconSystemName
    }
    
    func makeViewController(context: AppContext) -> AnyViewController {
        return AnyViewController {
            BuilderViewController(nibName: nil, bundle: nil)
        }
    }
}

/// UI provider that contributes a TabBarController to the mainView surface.
public final class BuilderUIProvider: UIProvider {
    public init() {}
    
    public func registerUI(_ registry: UIRegistry) async {
        let contribution = HomeTabContribution()
        await registry.contributeAsync(to: TabBarUISurface.builder, item: contribution)
    }
}
