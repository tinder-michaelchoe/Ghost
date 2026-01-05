//
//  NavigationService.swift
//  CoreContracts
//
//  Created by Claude on 12/31/25.
//

import Foundation
import UIKit

/// Protocol for tab navigation.
/// Implemented by TabBar, used by deeplink handlers to switch tabs.
/// Methods are MainActor-isolated since they interact with UI.
public protocol NavigationService: AnyObject {

    /// Switches to the specified tab and waits for the transition to complete.
    /// - Parameter identifier: The tab identifier (e.g., "dashboard", "settings")
    /// - Returns: The view controller for the tab, or nil if tab not found
    @MainActor
    func switchToTab(_ identifier: String) async -> UIViewController?

    /// Returns the currently selected tab identifier.
    @MainActor
    var currentTab: String? { get }

    /// Returns the view controller for the current tab.
    /// Useful for presenting sheets or other modal content.
    @MainActor
    var currentViewController: UIViewController? { get }
}
