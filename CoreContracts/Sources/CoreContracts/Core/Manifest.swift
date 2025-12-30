//
//  Manifest.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/24/25.
//

public protocol Manifest {
    static var serviceProviders: [ServiceProvider.Type] { get }
    static var uiProviders: [UIProvider.Type] { get }
    static var lifecycleParticipants: [LifecycleParticipant.Type] { get }
    static var appDelegateListeners: [AppDelegateListener.Type] { get }
    static var sceneDelegateListeners: [SceneDelegateListener.Type] { get }
}

public extension Manifest {
    static var serviceProviders: [ServiceProvider.Type] { [] }
    static var uiProviders: [UIProvider.Type] { [] }
    static var lifecycleParticipants: [LifecycleParticipant.Type] { [] }
    static var appDelegateListeners: [AppDelegateListener.Type] { [] }
    static var sceneDelegateListeners: [SceneDelegateListener.Type] { [] }
}
