//
//  DeeplinkService.swift
//  CoreContracts
//
//  Created by Claude on 12/31/25.
//

import Foundation

/// Service protocol for deep link routing.
/// Modules register handlers and the service routes incoming links.
/// Methods are MainActor-isolated since they interact with UI handlers.
public protocol DeeplinkService: AnyObject {

    /// Registers a handler for deep links.
    /// - Parameter handler: The handler to register
    @MainActor
    func register(handler: DeeplinkHandler)

    /// Unregisters a handler.
    /// - Parameter handler: The handler to remove
    @MainActor
    func unregister(handler: DeeplinkHandler)

    /// Attempts to handle a deep link.
    /// - Parameter deeplink: The parsed deep link
    /// - Returns: true if a handler processed the link, false otherwise
    @MainActor
    func handle(_ deeplink: Deeplink) -> Bool

    /// Checks if any registered handler can handle the given URL.
    /// - Parameter url: The URL to check
    /// - Returns: true if a handler exists for this URL's feature
    @MainActor
    func canHandle(_ url: URL) -> Bool
}
