//
//  WeatherWidgetContribution.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather Widget Contribution

/// Metadata for the weather widget contribution.
/// The factory is registered separately in WeatherUIProvider.
public struct WeatherWidgetContribution: WidgetContribution, Sendable {

    // MARK: - ViewContribution

    public let id = ViewContributionID(rawValue: "weather.widget")

    // MARK: - WidgetContribution

    public let size: WidgetSize = .medium
    public let title: String = "Weather"
    public let priorityTier: WidgetPriorityTier = .pinned

    // MARK: - Init

    public init() {}
}
