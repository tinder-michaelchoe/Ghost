//
//  LifecycleManager.swift
//  Ghost
//
//  Created by mexicanpizza on 12/25/25.
//

import Foundation
import CoreContracts

/// Manages lifecycle participant registration and phase execution.
/// Handles LifecycleParticipant registration and orchestrates lifecycle phases.
final class LifecycleManager {
    private var participants: [LifecycleParticipant] = []
    
    /// Register lifecycle participants.
    /// - Parameter participants: Array of LifecycleParticipant types to register
    func register(participants: [LifecycleParticipant.Type]) {
        for participantType in participants {
            let instance = participantType.init()
            self.participants.append(instance)
        }
    }
    
    /// Run all registered participants through a lifecycle phase.
    /// - Parameters:
    ///   - phase: The lifecycle phase to execute
    ///   - context: The app context to pass to participants
    func runPhase(_ phase: LifecyclePhase, context: AppContext) async {
        for participant in participants {
            await participant.run(phase: phase, context: context)
        }
    }
}

