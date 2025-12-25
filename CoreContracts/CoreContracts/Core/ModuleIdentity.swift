//
//  ModuleIdentity.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Optional protocol for modules that need identity and dependency management.
/// Modules can conform to this if they need to declare dependencies or be referenced by ID.
public protocol ModuleIdentity {
    /// Unique identifier for this module.
    static var id: String { get }
    
    /// Other modules this module depends on.
    /// Used for dependency resolution and ordering.
    static var dependencies: [any ModuleIdentity.Type] { get }
}

public extension ModuleIdentity {
    static var dependencies: [any ModuleIdentity.Type] { [] }
}

