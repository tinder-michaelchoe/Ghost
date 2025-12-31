//
//  LoggingPlugin.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

/// Logging module that provides a logging service.
/// Conforms to ServiceProvider (registers services) and LifecycleParticipant (initializes on launch).
public final class LoggingServiceProvider: ServiceProvider, LifecycleParticipant {
    /// The logger instance created during registration
    private var logger: LoggingService?

    public init() {}

    public func registerServices(_ registry: ServiceRegistry) {
        let logger = ConsoleLogger()
        self.logger = logger
        registry.register(LoggingService.self) {
            logger
        }
    }

    public func run(phase: LifecyclePhase) async {
        if phase == .launch {
            logger?.log("LoggingServiceProvider initialized", level: .info)
        }
    }
}
