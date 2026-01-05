//
//  NavigationServiceHolder.swift
//  TabBar
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import Foundation
import UIKit

/// Provides navigation functionality by finding the TabBarController at runtime.
/// This avoids the need for singleton patterns or complex registration.
public final class NavigationServiceHolder: NavigationService {

    /// Tab identifiers in the same order as TabBarController.buildTabs.
    private static let tabIdentifiers = ["home", "builder", "dashboard", "settings"]

    public init() {}

    /// Finds the UITabBarController from the key window's root view controller.
    @MainActor
    private var tabBarController: UITabBarController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController as? UITabBarController
    }

    @MainActor
    public func switchToTab(_ identifier: String) async -> UIViewController? {
        guard let index = Self.tabIdentifiers.firstIndex(of: identifier),
              let tabBar = tabBarController,
              let viewControllers = tabBar.viewControllers,
              index < viewControllers.count else {
            return nil
        }

        let targetVC = viewControllers[index]
        tabBar.selectedIndex = index

        // If there's a transition coordinator, wait for it to complete
        if let coordinator = targetVC.transitionCoordinator {
            await withCheckedContinuation { continuation in
                coordinator.animate(alongsideTransition: nil) { _ in
                    continuation.resume()
                }
            }
        }

        // Return the current view controller (unwrapping navigation controller if needed)
        return currentViewController
    }

    @MainActor
    public var currentTab: String? {
        guard let tabBar = tabBarController else { return nil }
        let index = tabBar.selectedIndex
        guard index < Self.tabIdentifiers.count else { return nil }
        return Self.tabIdentifiers[index]
    }

    @MainActor
    public var currentViewController: UIViewController? {
        guard let tabBar = tabBarController,
              let viewControllers = tabBar.viewControllers,
              tabBar.selectedIndex < viewControllers.count else {
            return nil
        }
        let selectedVC = viewControllers[tabBar.selectedIndex]
        // If it's a navigation controller, return the top view controller
        if let navController = selectedVC as? UINavigationController {
            return navController.topViewController ?? navController
        }
        return selectedVC
    }
}
