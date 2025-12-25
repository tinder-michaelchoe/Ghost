//
//  ViewContributionID.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation

/// Stable identifier for UI contributions.
public struct ViewContributionID: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}
