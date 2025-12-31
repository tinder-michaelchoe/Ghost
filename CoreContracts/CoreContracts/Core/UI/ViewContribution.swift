//
//  ViewContribution.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

import SwiftUI

// MARK: - View Contribution

/// Base protocol for a contributed piece of UI.
/// Contributions are pure metadata - factories are registered separately.
public protocol ViewContribution: Sendable {
    var id: ViewContributionID { get }
}

/// Stable identifier for UI contributions.
public struct ViewContributionID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Inline Contribution

/// A simple inline contribution with just an ID.
/// Use this when you don't need custom metadata.
public struct InlineContribution: ViewContribution, Sendable {
    public let id: ViewContributionID

    public init(id: String) {
        self.id = ViewContributionID(rawValue: id)
    }
}

// MARK: - Resolved Contribution

/// A contribution paired with its factory for creating views.
/// The registry stores these and invokes the factory when views are needed.
public struct ResolvedContribution: Sendable {
    public let contribution: any ViewContribution
    public let viewFactory: @MainActor @Sendable () -> AnyViewController

    public init(
        contribution: any ViewContribution,
        viewFactory: @escaping @MainActor @Sendable () -> AnyViewController
    ) {
        self.contribution = contribution
        self.viewFactory = viewFactory
    }

    @MainActor
    public func makeViewController() -> AnyViewController {
        viewFactory()
    }
}
