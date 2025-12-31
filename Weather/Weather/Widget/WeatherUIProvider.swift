//
//  WeatherUIProvider.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts

/// UI provider that contributes the weather widget to the dashboard.
public final class WeatherUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        // Register widget as a regular contribution
        // The factory returns a FlippableWidgetProviding container
        registry.contribute(
            to: DashboardUISurface.widgets,
            contribution: WeatherWidgetContribution(),
            dependencies: (WeatherService.self, PersistenceService.self, LocationService.self),
            factory: { weatherService, persistenceService, locationService in
                WeatherWidgetContainer(
                    weatherService: weatherService,
                    persistenceService: persistenceService,
                    locationService: locationService
                )
            }
        )
    }
}
