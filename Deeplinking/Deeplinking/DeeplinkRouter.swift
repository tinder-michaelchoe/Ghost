//
//  DeeplinkRouter.swift
//  Deeplinking
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import Foundation

/// Central router for deep links.
/// Maintains a registry of handlers keyed by feature name.
/// Routes incoming links to the appropriate handler based on the first path component.
public final class DeeplinkRouter: DeeplinkService {

    // MARK: - Properties

    /// Registered handlers, keyed by feature name
    private var handlers: [String: DeeplinkHandler] = [:]

    /// Navigation service for switching tabs
    private var navigationService: NavigationService?

    /// Expected URL scheme
    private let scheme: String

    // MARK: - Initialization

    public init(scheme: String = "ghost") {
        self.scheme = scheme
    }

    // MARK: - Configuration

    /// Sets the navigation service for tab switching.
    /// Called during configuration after services are available.
    @MainActor
    public func setNavigationService(_ service: NavigationService) {
        self.navigationService = service
    }

    // MARK: - DeeplinkService

    @MainActor
    public func register(handler: DeeplinkHandler) {
        handlers[handler.feature] = handler
        print("[DeeplinkRouter] Registered handler for feature: \(handler.feature)")
    }

    @MainActor
    public func unregister(handler: DeeplinkHandler) {
        handlers.removeValue(forKey: handler.feature)
        print("[DeeplinkRouter] Unregistered handler for feature: \(handler.feature)")
    }

    @MainActor
    public func handle(_ deeplink: Deeplink) -> Bool {
        // Validate scheme
        guard deeplink.scheme == scheme else {
            print("[DeeplinkRouter] Ignoring deeplink with scheme: \(deeplink.scheme)")
            return false
        }

        var handled = false

        // Step 1: Switch to tab if specified
        if let tab = deeplink.tab {
            if let navService = navigationService {
                let switched = navService.switchToTab(tab)
                print("[DeeplinkRouter] Switched to tab '\(tab)': \(switched)")
                handled = switched
            } else {
                print("[DeeplinkRouter] Warning: No NavigationService configured, cannot switch to tab '\(tab)'")
            }
        }

        // Step 2: If feature specified, delegate to handler
        if let feature = deeplink.feature {
            if let handler = handlers[feature] {
                print("[DeeplinkRouter] Routing to handler for feature: \(feature)")
                let featureHandled = handler.handle(deeplink)
                handled = handled || featureHandled
            } else {
                print("[DeeplinkRouter] No handler for feature: \(feature) (tab switch still applied)")
            }
        }

        return handled
    }

    @MainActor
    public func canHandle(_ url: URL) -> Bool {
        guard url.scheme == scheme else { return false }

        // Parse to get feature
        guard let deeplink = Deeplink(url: url) else { return false }

        // We can handle any deeplink with a valid tab or a registered feature handler
        if deeplink.tab != nil {
            return true
        }

        if let feature = deeplink.feature {
            return handlers[feature] != nil
        }

        return false
    }
}
