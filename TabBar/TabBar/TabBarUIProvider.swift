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

    public func registerUI(_ registry: UIRegistryContributing) {
        // Capture the registry for tab building
        registry.contribute(to: AppUISurface.mainView, id: "tabbar-main-view") { [registry] in
            TabBarController(uiRegistry: registry)
        }
    }
}
