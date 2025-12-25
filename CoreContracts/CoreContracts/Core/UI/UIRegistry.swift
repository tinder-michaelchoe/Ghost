//
//  UIRegistry.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

/// Registry for UI contributions.
public protocol UIRegistry {
    func contribute<T: UISurface>(to surface: T, item: some ViewContribution)
    /// Async version for use during initialization to ensure contributions are registered.
    func contributeAsync<T: UISurface>(to surface: T, item: some ViewContribution) async
}
