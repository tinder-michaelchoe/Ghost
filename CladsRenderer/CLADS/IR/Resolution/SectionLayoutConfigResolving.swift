//
//  SectionLayoutConfigResolving.swift
//  CLADS
//
//  Protocol and registry for resolving section layout configurations.
//

import Foundation
import SwiftUI

// MARK: - Section Layout Config Resolving Protocol

/// Protocol for resolving a specific section layout type from Document to IR.
///
/// Implement this protocol to add support for new section layout types.
///
/// Example:
/// ```swift
/// struct CarouselLayoutConfigResolver: SectionLayoutConfigResolving {
///     static let layoutType = Document.SectionType.carousel
///
///     func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
///         // Custom resolution logic
///     }
/// }
/// ```
public protocol SectionLayoutConfigResolving {
    /// The section layout type this resolver handles
    static var layoutType: Document.SectionType { get }
    
    /// Resolve the document config into IR types
    /// - Parameter config: The document-level section layout configuration
    /// - Returns: The resolved IR section type and config
    func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult
}

// MARK: - Resolution Result

/// The result of resolving a section layout configuration
public struct SectionLayoutConfigResult {
    /// The resolved section type (list, grid, flow, horizontal, etc.)
    public let sectionType: IR.SectionType
    
    /// The resolved section configuration
    public let sectionConfig: IR.SectionConfig
    
    public init(sectionType: IR.SectionType, sectionConfig: IR.SectionConfig) {
        self.sectionType = sectionType
        self.sectionConfig = sectionConfig
    }
}

// MARK: - Section Layout Config Resolver Registry

/// Registry for section layout config resolvers.
///
/// Register resolvers for different layout types to enable extensible layout resolution.
public final class SectionLayoutConfigResolverRegistry: @unchecked Sendable {
    
    private var resolvers: [Document.SectionType: any SectionLayoutConfigResolving] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    /// Register a resolver for a specific layout type
    public func register<R: SectionLayoutConfigResolving>(_ resolver: R) {
        lock.lock()
        defer { lock.unlock() }
        resolvers[R.layoutType] = resolver
    }
    
    /// Check if a resolver exists for the given layout type
    public func hasResolver(for type: Document.SectionType) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return resolvers[type] != nil
    }
    
    /// Resolve a section layout configuration
    /// - Parameter config: The document-level configuration to resolve
    /// - Returns: The resolution result, or nil if no resolver is registered
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult? {
        lock.lock()
        let resolver = resolvers[config.type]
        lock.unlock()
        
        return resolver?.resolve(config: config)
    }
}
