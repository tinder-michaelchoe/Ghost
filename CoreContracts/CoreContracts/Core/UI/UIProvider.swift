//
//  UIProvider.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for modules that provide UI contributions.
/// Conform to this if your module contributes UI to surfaces (tabs, settings, etc.).
public protocol UIProvider {
    init()
    /// Register UI contributions provided by this module.
    func registerUI(_ registry: UIRegistry) async
}

