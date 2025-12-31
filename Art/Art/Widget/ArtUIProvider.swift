//
//  ArtUIProvider.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts

/// UI provider that contributes the art widget to the dashboard.
public final class ArtUIProvider: UIProvider {
    public init() {}

    public func registerUI(_ registry: UIRegistryContributing) {
        // Register widget as a regular contribution
        // The factory returns a FlippableWidgetProviding container
        registry.contribute(
            to: DashboardUISurface.widgets,
            contribution: ArtWidgetContribution(),
            dependencies: (ArtSearching.self, WeatherService.self, PersistenceService.self),
            factory: { artService, weatherService, persistenceService in
                ArtWidgetContainer(
                    artService: artService,
                    weatherService: weatherService,
                    persistenceService: persistenceService
                )
            }
        )
    }
}
