//
//  type.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation

public typealias ServiceContainerType = ServiceRegistry & ServiceResolver

/// Registers services by protocol type with an associated capability.
public protocol ServiceRegistry {
    func register<T>(_ type: T.Type, factory: @escaping (AppContext) -> T)
}

/// Resolves services by protocol type.
public protocol ServiceResolver {
    func resolve<T>(_ type: T.Type) -> T?
}
