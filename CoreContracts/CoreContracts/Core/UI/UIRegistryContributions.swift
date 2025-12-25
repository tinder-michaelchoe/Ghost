//
//  UIRegistryContributions.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for querying UI registry contributions.
/// This allows modules like TabBar to query for contributions from specific surfaces.
public protocol UIRegistryContributions {
    func getContributions<T: UISurface>(for surface: T) async -> [any ViewContribution]
}

