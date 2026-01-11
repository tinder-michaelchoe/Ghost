//
//  ActionTypes.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Navigation Presentation

extension Document {
    /// Presentation style for navigation
    public enum NavigationPresentation: String, Codable, Sendable {
        case push
        case present
        case fullScreen
    }
}

// MARK: - Alert Button Style

extension Document {
    /// Button style for alerts
    public enum AlertButtonStyle: String, Codable, Sendable {
        case `default`
        case cancel
        case destructive
    }
}
