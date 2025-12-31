//
//  TabBarController.swift
//  TabBarFramework
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts
import Foundation
import SwiftUI
import UIKit

/// Tab bar controller that composes tabs from UI contributions.
@MainActor
final class TabBarController: UITabBarController {
    private let uiRegistry: UIRegistryContributing

    init(uiRegistry: UIRegistryContributing) {
        self.uiRegistry = uiRegistry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildTabs()
    }

    private func buildTabs() {
        // Get tab bar contributions for each tab surface
        let tabSurfaces: [TabBarUISurface] = [.home, .builder, .dashboard, .settings]

        var allResolved: [ResolvedContribution] = []
        for surface in tabSurfaces {
            let contributions = uiRegistry.contributions(for: surface)
            allResolved += contributions
        }

        let viewControllers: [UIViewController] = allResolved
            .compactMap { resolved in
                // Create the view controller using the resolved factory
                let anyVC = resolved.makeViewController()
                guard let viewController = anyVC.build() as? UIViewController else {
                    print("⚠️ Failed to build view controller for \(resolved.contribution.id.rawValue)")
                    return nil
                }

                // Configure tab bar item if contribution provides metadata
                if let tabBarItem = resolved.contribution as? TabBarItemProviding {
                    if let title = tabBarItem.tabBarTitle {
                        viewController.title = title
                    }

                    if let iconName = tabBarItem.tabBarIconSystemName {
                        viewController.tabBarItem = UITabBarItem(
                            title: tabBarItem.tabBarTitle,
                            image: UIImage(systemName: iconName),
                            selectedImage: UIImage(systemName: iconName)
                        )
                    }
                }
                return viewController
            }
        setViewControllers(viewControllers, animated: false)
    }
}

