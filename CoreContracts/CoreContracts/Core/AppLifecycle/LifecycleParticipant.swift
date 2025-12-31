//
//  LifecycleParticipant.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/23/25.
//

import Foundation

/// Protocol for modules that participate in app lifecycle phases.
/// Conform to this if your module needs to perform work during specific lifecycle phases.
/// Dependencies should be injected via init or stored during service registration.
public protocol LifecycleParticipant {
    init()
    /// Called by the kernel for each lifecycle phase.
    /// - Parameter phase: The current lifecycle phase
    func run(phase: LifecyclePhase) async
}

