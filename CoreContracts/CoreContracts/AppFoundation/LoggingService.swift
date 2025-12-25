//
//  LoggingService.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//

/// Protocol for logging service
public protocol LoggingService: Sendable {
    func start()
    func log(_ message: String, level: LogLevel)
}

public extension LoggingService {
    func start() {}
}

public enum LogLevel: String, Sendable {
    case debug, info, warning, error
}
