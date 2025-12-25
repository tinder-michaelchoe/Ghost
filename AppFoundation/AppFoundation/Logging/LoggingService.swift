//
//  LoggingService.swift
//  AppFoundation
//
//  Created by mexicanpizza on 12/22/25.
//

import CoreContracts
import Foundation

/// Simple console logger implementation
final class ConsoleLogger: LoggingService {
    
    func start() {
        log("ConsoleLogger started", level: .info)
    }
    
    func log(_ message: String, level: LogLevel) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [\(level.rawValue.uppercased())] \(message)")
    }
}

final class FileLogger: LoggingService {
    func log(_ message: String, level: LogLevel) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("Should write to file: [\(timestamp)] [\(level.rawValue.uppercased())] \(message)")
    }
}
