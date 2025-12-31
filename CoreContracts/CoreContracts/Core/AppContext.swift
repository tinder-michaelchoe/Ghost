//
//  BuildInfo.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation

/// Build metadata for diagnostics and display.
public struct BuildInfo {
    public let appVersion: String
    public let buildNumber: String
    public init(appVersion: String, buildNumber: String) {
        self.appVersion = appVersion
        self.buildNumber = buildNumber
    }
}

/// App configuration available to all plugins.
public struct AppConfig {
    public let buildInfo: BuildInfo
    public init(buildInfo: BuildInfo) {
        self.buildInfo = buildInfo
    }
}
