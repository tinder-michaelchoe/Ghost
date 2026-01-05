//
//  DeeplinkHandler.swift
//  CoreContracts
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Protocol for modules that handle deep links.
/// Each handler is responsible for a specific feature (e.g., "weather", "art").
/// Methods are MainActor-isolated since they interact with UI.
public protocol DeeplinkHandler: AnyObject {

    /// The feature this handler responds to (first path component).
    /// e.g., "weather", "art"
    /// The router uses this to match incoming deeplinks.
    var feature: String { get }

    /// Handles a deep link.
    /// The handler is responsible for:
    /// 1. Navigating to the correct tab (from deeplink.tab) if needed
    /// 2. Performing the feature-specific action (from deeplink.action)
    /// - Parameter deeplink: The parsed deep link
    /// - Returns: true if the deep link was handled, false otherwise
    @MainActor
    func handle(_ deeplink: Deeplink) async -> Bool
}
