//
//  ViewContribution.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

import SwiftUI

/// Base protocol for a contributed piece of UI.
public protocol ViewContribution {
    var id: ViewContributionID { get }
}

/// Stable identifier for UI contributions.
public struct ViewContributionID: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

/// Protocol for contributions that provide UIKit view controllers.
public protocol UIKitViewContribution: ViewContribution {
    @MainActor func makeViewController(context: AppContext) -> AnyViewController
}

/// Protocol for contributions that provide SwiftUI views.
public protocol SwiftUIViewContribution: ViewContribution {
    @MainActor func makeSwiftUIView(context: AppContext) -> AnyView
}
