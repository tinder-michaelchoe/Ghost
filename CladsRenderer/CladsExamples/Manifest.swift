//
//  Manifest.swift
//  CladsExamples
//
//  Created by mexicanpizza on 12/24/25.
//

import CoreContracts

public enum CladsExamplesManifest: Manifest {
    public static var uiProviders: [UIProvider.Type] {
        [
            CladsExamplesUIProvider.self
        ]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [CladsExamplesSceneDelegateListener.self]
    }
}

// MARK: - SceneDelegate Listener

/// Registers the examples deeplink handler when the scene connects.
@MainActor
public final class CladsExamplesSceneDelegateListener: SceneDelegateListener {

    private var deeplinkHandler: DeeplinkExampleHandler?

    public required init() {}

    public func configure(with resolver: ServiceResolver) {
        guard let deeplinkService = resolver.resolve(DeeplinkService.self),
              let navigationService = resolver.resolve(NavigationService.self) else {
            print("[CladsExamplesListener] DeeplinkService or NavigationService not available")
            return
        }

        let handler = DeeplinkExampleHandler(navigationService: navigationService)
        self.deeplinkHandler = handler

        deeplinkService.register(handler: handler)
        print("[CladsExamplesListener] Registered deeplink handler")
    }
}
