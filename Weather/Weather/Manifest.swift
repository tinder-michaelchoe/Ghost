//
//  Manifest.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

public enum WeatherManifest: Manifest {
    public static var serviceProviders: [ServiceProvider.Type] {
        [WeatherServiceProvider.self]
    }

    public static var uiProviders: [UIProvider.Type] {
        [WeatherUIProvider.self]
    }

    public static var sceneDelegateListeners: [SceneDelegateListener.Type] {
        [WeatherSceneDelegateListener.self]
    }
}

// MARK: - SceneDelegate Listener

/// Registers the weather deeplink handler when the scene connects.
public final class WeatherSceneDelegateListener: SceneDelegateListener {

    private var deeplinkHandler: WeatherDeeplinkHandler?

    public required init() {}

    @MainActor
    public func configure(with resolver: ServiceResolver) {
        guard let persistenceService = resolver.resolve(PersistenceService.self),
              let deeplinkService = resolver.resolve(DeeplinkService.self) else {
            print("[WeatherListener] Missing required services for deeplink handler")
            return
        }

        let handler = WeatherDeeplinkHandler(persistenceService: persistenceService)
        self.deeplinkHandler = handler

        deeplinkService.register(handler: handler)
        print("[WeatherListener] Registered deeplink handler")
    }
}
