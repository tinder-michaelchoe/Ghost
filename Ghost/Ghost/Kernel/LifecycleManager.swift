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
    private var participants: [(type: String, instance: LifecycleParticipant)] = []
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[LifecycleManager] [\(timestamp)] \(message)")
    }

    /// Register lifecycle participants.
    /// - Parameter participants: Array of LifecycleParticipant types to register
    func register(participants: [LifecycleParticipant.Type]) {
        log("📋 Registering \(participants.count) lifecycle participant(s)")
        for participantType in participants {
            let typeName = String(describing: participantType)
            let instance = participantType.init()
            self.participants.append((type: typeName, instance: instance))
            log("  ├── ✅ \(typeName)")
        }
        log("📋 Registration complete")
    }

    /// Run all registered participants through a lifecycle phase.
    /// - Parameter phase: The lifecycle phase to execute
    func runPhase(_ phase: LifecyclePhase) async {
        let phaseStartTime = CFAbsoluteTimeGetCurrent()
        log("🔄 Phase [\(phase)] starting with \(participants.count) participant(s)")
        
        for (typeName, participant) in participants {
            let startTime = CFAbsoluteTimeGetCurrent()
            await participant.run(phase: phase)
            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            log("  ├── ⏱️ \(typeName).\(phase) completed in \(String(format: "%.2f", duration))ms")
        }
        
        let totalDuration = (CFAbsoluteTimeGetCurrent() - phaseStartTime) * 1000
        log("🔄 Phase [\(phase)] completed in \(String(format: "%.2f", totalDuration))ms")
    }
    
    /// Dumps all registered lifecycle participants for debugging.
    /// Shows the complete participant list from this centralized orchestrator.
    func dumpParticipants() {
        print("")
        print("╔══════════════════════════════════════════════════════════════════╗")
        print("║            LIFECYCLE MANAGER - REGISTERED PARTICIPANTS           ║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Total Participants: \(participants.count.description.padding(toLength: 45, withPad: " ", startingAt: 0))║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        
        for (index, (typeName, _)) in participants.enumerated() {
            let prefix = index == participants.count - 1 ? "└──" : "├──"
            print("║ \(prefix) \(typeName.padding(toLength: 61, withPad: " ", startingAt: 0))║")
        }
        
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Phases: prewarm → launch → sceneConnect → postUI → bgRefresh    ║")
        print("╚══════════════════════════════════════════════════════════════════╝")
        print("")
    }
}
