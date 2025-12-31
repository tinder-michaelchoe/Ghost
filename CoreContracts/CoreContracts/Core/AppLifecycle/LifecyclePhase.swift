//
//  LifecyclePhase.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation

/// Phases the kernel runs in deterministic order.
public enum LifecyclePhase: CaseIterable {
    case prewarm
    case launch
    case sceneConnect
    case postUI
    case backgroundRefresh
}

/// Types that participate in lifecycle orchestration.
public protocol LifecycleRunnable {
    /// Called by the kernel for each lifecycle phase.
    func run(phase: LifecyclePhase) async
}
