//
//  ActionTypes.swift
//  CladsRendererFramework
//

import Foundation

/// Presentation style for navigation
public enum NavigationPresentation: String, Codable {
    case push
    case present
    case fullScreen
}

/// Button style for alerts
public enum AlertButtonStyle: String, Codable {
    case `default`
    case cancel
    case destructive
}
