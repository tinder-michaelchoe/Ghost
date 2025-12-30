//
//  WeatherWidgetContribution.swift
//  Weather
//
//  Created by mexicanpizza on 12/30/25.
//

import CoreContracts
import UIKit

// MARK: - Weather Widget Contribution

public struct WeatherWidgetContribution: WidgetContribution {

    // MARK: - ViewContribution

    public let id = ViewContributionID(rawValue: "weather.widget")

    // MARK: - WidgetContribution

    public let size: WidgetSize = .medium
    public let title: String = "Weather"
    public let priorityTier: WidgetPriorityTier = .pinned

    // MARK: - Init

    public init() {}

    // MARK: - View Factory

    @MainActor
    public func makeFrontViewController(context: AppContext) -> UIViewController {
        WeatherWidgetViewController(context: context)
    }

    @MainActor
    public func makeBackViewController(context: AppContext) -> UIViewController? {
        WeatherCityPickerViewController(context: context)
    }
}
