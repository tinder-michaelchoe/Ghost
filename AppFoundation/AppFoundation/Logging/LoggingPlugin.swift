//
//  LoggingPlugin.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/23/25.
//

import CoreContracts

/// Logging module that provides a logging service.
/// Conforms to ServiceProvider (registers services) and LifecycleParticipant (initializes on launch).
public final class LoggingServiceProvider: ServiceProvider, LifecycleParticipant, ModuleIdentity {
    public static let id: String = "com.ghost.logging"
    public static let dependencies: [any ModuleIdentity.Type] = []
    
    public init() {}
    
    public func registerServices(_ registry: ServiceRegistry) {
        registry.register(LoggingService.self, factory: { _ in
            ConsoleLogger()
        })
    }
    
    public func run(phase: LifecyclePhase, context: AppContext) async {
        if phase == .launch {
            if let logger = await context.services.resolve(LoggingService.self) {
                logger.log("LoggingServiceProvider initialized", level: .info)
            }
        }
    }
}
