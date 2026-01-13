//
//  SimpleRenderingTests.swift
//  CLADSTests
//
//  Minimal rendering tests to verify test framework works.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Simple Tests (No MainActor)

struct SimpleRenderingTests {
    
    @Test func renderNodeKindHasTextCase() {
        let kind = RenderNodeKind.text
        #expect(kind == .text)
    }
    
    @Test func renderNodeKindHasButtonCase() {
        let kind = RenderNodeKind.button
        #expect(kind == .button)
    }
    
    @Test func renderNodeKindHasContainerCase() {
        let kind = RenderNodeKind.container
        #expect(kind == .container)
    }
    
    @Test func renderNodeKindCanBeCustom() {
        let kind = RenderNodeKind(rawValue: "custom")
        #expect(kind.rawValue == "custom")
    }
}
