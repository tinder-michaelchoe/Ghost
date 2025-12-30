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

    public func registerUI(_ registry: UIRegistryContributing) async {
        let contribution = WeatherWidgetContribution()
        registry.contribute(to: DashboardUISurface.widgets, item: contribution)
    }
}
