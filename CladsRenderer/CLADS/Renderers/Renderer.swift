//
//  Renderer.swift
//  CladsRendererFramework
//
//  Protocol for rendering a RenderTree to various outputs.
//

import Foundation

// MARK: - Renderer Protocol

/// A renderer that transforms a RenderTree into an output format
public protocol Renderer {
    associatedtype Output

    /// Render the tree into the output format
    func render(_ tree: RenderTree) -> Output
}
