//
//  LifecycleParticipant.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for modules that participate in app lifecycle phases.
/// Conform to this if your module needs to perform work during specific lifecycle phases.
public protocol LifecycleParticipant {
    init()
    /// Called by the kernel for each lifecycle phase.
    /// - Parameters:
    ///   - phase: The current lifecycle phase
    ///   - context: The app context providing access to services, etc.
    func run(phase: LifecyclePhase, context: AppContext) async
}

