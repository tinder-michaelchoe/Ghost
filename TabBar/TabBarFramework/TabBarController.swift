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
    private let context: AppContext
    private let uiRegistry: UIRegistryContributions
    
    init(context: AppContext, uiRegistry: UIRegistryContributions) {
        self.context = context
        self.uiRegistry = uiRegistry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await buildTabs()
        }
    }
    
    private func buildTabs() async {
        // Get tab bar contributions for each tab surface
        // For now, we'll query each TabBarUISurface case individually
        let tabSurfaces: [TabBarUISurface] = [.home, .builder, .settings]
        var allContributions: [any ViewContribution] = []
        
        for surface in tabSurfaces {
            let contributions = await uiRegistry.getContributions(for: surface)
            allContributions.append(contentsOf: contributions)
        }
        
        var viewControllers: [UIViewController] = []
        
        for contribution in allContributions {
            let viewController: UIViewController
            
            // Handle UIKit contributions
            if let uiKitContrib = contribution as? UIKitViewContribution {
                let anyVC = uiKitContrib.makeViewController(context: context)
                viewController = anyVC.build() as! UIViewController
            }
            // Handle SwiftUI contributions
            else if let swiftUIContrib = contribution as? SwiftUIViewContribution {
                let swiftUIView = swiftUIContrib.makeSwiftUIView(context: context).build()
                viewController = UIHostingController(rootView: swiftUIView)
            } else {
                print("⚠️ No view builder for contribution \(contribution.id.rawValue)")
                continue
            }
            
            // Configure tab bar item if contribution provides metadata
            if let tabBarItem = contribution as? TabBarItemProviding {
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
            
            viewControllers.append(viewController)
        }
        let testViewController = UIViewController(nibName: nil, bundle: nil)
        testViewController.view.backgroundColor = .systemBlue
        
        let testViewController2 = UIViewController(nibName: nil, bundle: nil)
        testViewController2.view.backgroundColor = .systemPink
        
        //setViewControllers([testViewController, testViewController2], animated: false)
        setViewControllers(viewControllers, animated: false)
    }
}

