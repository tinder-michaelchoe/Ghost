//
//  UISurface.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/22/25.
//


import Foundation
import SwiftUI

/// Protocol for UI surfaces that modules can contribute to.
/// Any Hashable type (typically an enum) can conform to this protocol
/// to define a surface that other modules can contribute UI to.
public protocol UISurface: Hashable {}

/// App-wide UI surfaces managed by the kernel.
public enum AppUISurface: UISurface {
    case mainView
}

/// Type-erased SwiftUI view builder.
public struct AnySwiftUIView {
    public let build: () -> AnyView
    public init(_ build: @escaping () -> AnyView) { self.build = build }
}

/// Type-erased UIViewController builder without imposing UIKit dependency on signatures.
public struct AnyViewController {
    public let build: () -> Any
    public init(_ build: @escaping () -> Any) { self.build = build }
}
