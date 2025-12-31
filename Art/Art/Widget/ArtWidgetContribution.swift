//
//  ArtWidgetContribution.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import UIKit

// MARK: - Art Widget Contribution

/// Metadata for the art widget contribution.
public struct ArtWidgetContribution: WidgetContribution, Sendable {

    // MARK: - ViewContribution

    public let id = ViewContributionID(rawValue: "art.widget")

    // MARK: - WidgetContribution

    public let size: WidgetSize = .large
    public let title: String = "Art"
    public let priorityTier: WidgetPriorityTier = .primary

    // MARK: - Init

    public init() {}
}
