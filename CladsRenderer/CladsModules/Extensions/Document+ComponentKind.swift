//
//  Document+ComponentKind.swift
//  CladsRenderer
//
//  Created by mexicanpizza on 1/4/26.
//

import CLADS

// MARK: - Built-in Component Kinds

extension Document.ComponentKind {
    /// Text label component
    public static let label = Document.ComponentKind(rawValue: "label")

    /// Tappable button component
    public static let button = Document.ComponentKind(rawValue: "button")

    /// Text input field component
    public static let textfield = Document.ComponentKind(rawValue: "textfield")

    /// Image component (SF Symbols or URL)
    public static let image = Document.ComponentKind(rawValue: "image")

    /// Gradient background component
    public static let gradient = Document.ComponentKind(rawValue: "gradient")

    /// Boolean toggle switch component
    public static let toggle = Document.ComponentKind(rawValue: "toggle")

    /// Value slider component
    public static let slider = Document.ComponentKind(rawValue: "slider")

    /// Divider/separator component
    public static let divider = Document.ComponentKind(rawValue: "divider")
}
