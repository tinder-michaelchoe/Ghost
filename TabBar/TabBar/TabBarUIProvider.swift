//
//  TabBarUIProvider.swift
//  TabBarFramework
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation
import CoreContracts
import UIKit

/// UI provider that contributes a TabBarController to the mainView surface.
public final class TabBarUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) async {

        struct MainViewContribution: UIKitViewContribution {

            let id: ViewContributionID
            let makeViewController: (@MainActor (AppContext) -> AnyViewController)

            init(
                id: ViewContributionID = ViewContributionID(rawValue: "tabbar-main-view"),
                makeViewController: @escaping (@MainActor (AppContext) -> AnyViewController)
            ) {
                self.id = id
                self.makeViewController = makeViewController
            }
            
            func makeViewController(context: AppContext) -> AnyViewController {
                return makeViewController(context)
            }
        }
        
        print("✅ TabBarUIProvider: Registering mainView contribution")

        let contribution = MainViewContribution { context in
            print("✅ TabBarUIProvider: Creating test view controller")
            return AnyViewController {
                TabBarController(context: context, uiRegistry: registry)
            }
        }

        // Register contribution synchronously
        registry.contribute(to: AppUISurface.mainView, item: contribution)
        print("✅ TabBarUIProvider: Contribution registered to AppUISurface.mainView")
    }
}
