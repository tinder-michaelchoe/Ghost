//
//  DeeplinkSceneDelegateListener.swift
//  Deeplinking
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import UIKit

/// SceneDelegate listener that receives URLs and routes them through DeeplinkService.
public final class DeeplinkSceneDelegateListener: SceneDelegateListener {

    // MARK: - Properties

    /// Reference to the deeplink service (injected via configure)
    @MainActor
    private var deeplinkService: DeeplinkService?

    // MARK: - Initialization

    public required init() {}

    // MARK: - SceneDelegateListener

    /// Receives dependencies after services are registered.
    @MainActor
    public func configure(with resolver: ServiceResolver) {
        self.deeplinkService = resolver.resolve(DeeplinkService.self)

        // Configure the router with NavigationService for tab switching
        if let router = deeplinkService as? DeeplinkRouter,
           let navigationService = resolver.resolve(NavigationService.self) {
            router.setNavigationService(navigationService)
            print("[DeeplinkListener] Configured router with NavigationService")
        }

        print("[DeeplinkListener] Configured with DeeplinkService: \(deeplinkService != nil)")
    }

    @MainActor
    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) -> ServiceManagerProtocol? {
        // Handle URLs from cold launch
        // Note: This is called AFTER initializeApp and configure, so services are ready
        Task {
            await handleURLContexts(connectionOptions.urlContexts)
        }
        return nil
    }

    @MainActor
    public func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        // Handle URLs when app is already running
        Task {
            await handleURLContexts(urlContexts)
        }
    }

    // MARK: - Private

    @MainActor
    private func handleURLContexts(_ urlContexts: Set<UIOpenURLContext>) async {
        for context in urlContexts {
            await handleURL(context.url)
        }
    }

    @MainActor
    private func handleURL(_ url: URL) async {
        print("[DeeplinkListener] Received URL: \(url)")

        guard let deeplink = Deeplink(url: url) else {
            print("[DeeplinkListener] Failed to parse URL")
            return
        }

        guard let service = deeplinkService else {
            print("[DeeplinkListener] Error: DeeplinkService not configured")
            return
        }

        let handled = await service.handle(deeplink)
        print("[DeeplinkListener] Deeplink handled: \(handled)")
    }
}
