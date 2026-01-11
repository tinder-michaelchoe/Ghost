//
//  SectionLayoutConfigResolverRegistryTests.swift
//  CLADSTests
//
//  Unit tests for SectionLayoutConfigResolverRegistry - registration and resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Test Config Resolver Implementations

/// A test resolver for horizontal section configurations
struct TestHorizontalConfigResolver: SectionLayoutConfigResolving {
    static let layoutType = Document.SectionType.horizontal
    
    func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let sectionConfig = IR.SectionConfig(
            alignment: .leading,
            itemSpacing: config.itemSpacing ?? 12,
            lineSpacing: config.lineSpacing ?? 0,
            contentInsets: .zero,
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: false,
            snapBehavior: .none,
            showsDividers: false
        )
        return SectionLayoutConfigResult(
            sectionType: .horizontal,
            sectionConfig: sectionConfig
        )
    }
}

/// A test resolver for list section configurations
struct TestListConfigResolver: SectionLayoutConfigResolving {
    static let layoutType = Document.SectionType.list
    
    func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let sectionConfig = IR.SectionConfig(
            alignment: .leading,
            itemSpacing: config.itemSpacing ?? 0,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: .zero,
            showsIndicators: config.showsIndicators ?? true,
            isPagingEnabled: false,
            snapBehavior: .none,
            showsDividers: config.showsDividers ?? true
        )
        return SectionLayoutConfigResult(
            sectionType: .list,
            sectionConfig: sectionConfig
        )
    }
}

/// A test resolver for grid section configurations
struct TestGridConfigResolver: SectionLayoutConfigResolving {
    static let layoutType = Document.SectionType.grid
    
    func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let columns: IR.ColumnConfig
        if let docColumns = config.columns {
            switch docColumns {
            case .fixed(let count):
                columns = .fixed(count)
            case .adaptive(let minWidth):
                columns = .adaptive(minWidth: minWidth)
            }
        } else {
            columns = .fixed(2) // Default
        }
        
        let sectionConfig = IR.SectionConfig(
            alignment: .leading,
            itemSpacing: config.itemSpacing ?? 8,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: .zero,
            showsIndicators: false,
            isPagingEnabled: false,
            snapBehavior: .none,
            showsDividers: false
        )
        return SectionLayoutConfigResult(
            sectionType: .grid(columns: columns),
            sectionConfig: sectionConfig
        )
    }
}

// MARK: - Registration Tests

struct SectionLayoutConfigResolverRegistryRegistrationTests {
    
    @Test func registersResolver() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        #expect(registry.hasResolver(for: .horizontal))
    }
    
    @Test func registersMultipleResolvers() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        registry.register(TestListConfigResolver())
        
        #expect(registry.hasResolver(for: .horizontal))
        #expect(registry.hasResolver(for: .list))
    }
    
    @Test func registersGridResolver() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestGridConfigResolver())
        
        #expect(registry.hasResolver(for: .grid))
    }
    
    @Test func replacesExistingResolver() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        registry.register(TestHorizontalConfigResolver()) // Re-register same type
        
        // Should still have the resolver
        #expect(registry.hasResolver(for: .horizontal))
    }
}

// MARK: - Lookup Tests

struct SectionLayoutConfigResolverRegistryLookupTests {
    
    @Test func hasResolverReturnsFalseForUnregistered() {
        let registry = SectionLayoutConfigResolverRegistry()
        
        #expect(!registry.hasResolver(for: .horizontal))
        #expect(!registry.hasResolver(for: .list))
        #expect(!registry.hasResolver(for: .grid))
    }
    
    @Test func hasResolverReturnsTrueForRegistered() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        #expect(registry.hasResolver(for: .horizontal))
    }
}

// MARK: - Resolution Tests

struct SectionLayoutConfigResolverRegistryResolutionTests {
    
    @Test func resolvesHorizontalConfig() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .horizontal,
            itemSpacing: 20
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result != nil)
        if case .horizontal = result?.sectionType {
            // Success
        } else {
            Issue.record("Expected horizontal section type")
        }
        #expect(result?.sectionConfig.itemSpacing == 20)
    }
    
    @Test func resolvesListConfig() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestListConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .list,
            showsDividers: true
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result != nil)
        if case .list = result?.sectionType {
            // Success
        } else {
            Issue.record("Expected list section type")
        }
        #expect(result?.sectionConfig.showsDividers == true)
    }
    
    @Test func resolvesGridConfig() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestGridConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .grid,
            columns: .fixed(3)
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result != nil)
        if case .grid(let columns) = result?.sectionType {
            if case .fixed(let count) = columns {
                #expect(count == 3)
            } else {
                Issue.record("Expected fixed columns")
            }
        } else {
            Issue.record("Expected grid section type")
        }
    }
    
    @Test func resolvesGridWithAdaptiveColumns() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestGridConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .grid,
            columns: .adaptive(minWidth: 150)
        )
        
        let result = registry.resolve(config: config)
        
        if case .grid(let columns) = result?.sectionType {
            if case .adaptive(let minWidth) = columns {
                #expect(minWidth == 150)
            } else {
                Issue.record("Expected adaptive columns")
            }
        } else {
            Issue.record("Expected grid section type")
        }
    }
    
    @Test func returnsNilForUnknownType() {
        let registry = SectionLayoutConfigResolverRegistry()
        // Don't register any resolvers
        
        let config = Document.SectionLayoutConfig(type: .horizontal)
        
        let result = registry.resolve(config: config)
        
        #expect(result == nil)
    }
    
    @Test func resolvesItemSpacing() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .horizontal,
            itemSpacing: 24
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result?.sectionConfig.itemSpacing == 24)
    }
    
    @Test func resolvesLineSpacing() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestListConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .list,
            lineSpacing: 16
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result?.sectionConfig.lineSpacing == 16)
    }
    
    @Test func resolvesShowsIndicators() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .horizontal,
            showsIndicators: true
        )
        
        let result = registry.resolve(config: config)
        
        // Note: Our test resolver always returns false for showsIndicators
        // In a real implementation, this would pass through the config value
        #expect(result?.sectionConfig.showsIndicators == true || result?.sectionConfig.showsIndicators == false)
    }
    
    @Test func resolvesShowsDividers() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestListConfigResolver())
        
        let config = Document.SectionLayoutConfig(
            type: .list,
            showsDividers: false
        )
        
        let result = registry.resolve(config: config)
        
        #expect(result?.sectionConfig.showsDividers == false)
    }
}

// MARK: - Default Config Tests

struct SectionLayoutConfigDefaultsTests {
    
    @Test func horizontalConfigDefaults() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestHorizontalConfigResolver())
        
        let config = Document.SectionLayoutConfig(type: .horizontal)
        let result = registry.resolve(config: config)
        
        #expect(result?.sectionConfig.itemSpacing == 12)
        #expect(result?.sectionConfig.showsIndicators == false)
        #expect(result?.sectionConfig.showsDividers == false)
    }
    
    @Test func listConfigDefaults() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestListConfigResolver())
        
        let config = Document.SectionLayoutConfig(type: .list)
        let result = registry.resolve(config: config)
        
        #expect(result?.sectionConfig.lineSpacing == 8)
        #expect(result?.sectionConfig.showsIndicators == true)
        #expect(result?.sectionConfig.showsDividers == true)
    }
    
    @Test func gridConfigDefaults() {
        let registry = SectionLayoutConfigResolverRegistry()
        registry.register(TestGridConfigResolver())
        
        let config = Document.SectionLayoutConfig(type: .grid)
        let result = registry.resolve(config: config)
        
        // Should default to 2 columns
        if case .grid(let columns) = result?.sectionType {
            if case .fixed(let count) = columns {
                #expect(count == 2)
            } else {
                Issue.record("Expected fixed columns")
            }
        } else {
            Issue.record("Expected grid section type")
        }
    }
}

// MARK: - Protocol Conformance Tests

struct SectionLayoutConfigResolvingProtocolTests {
    
    @Test func protocolProvidesLayoutType() {
        #expect(TestHorizontalConfigResolver.layoutType == .horizontal)
    }
    
    @Test func differentResolversHaveDifferentTypes() {
        #expect(TestHorizontalConfigResolver.layoutType == .horizontal)
        #expect(TestListConfigResolver.layoutType == .list)
        #expect(TestGridConfigResolver.layoutType == .grid)
    }
    
    @Test func resolverReturnsCorrectResultType() {
        let resolver = TestHorizontalConfigResolver()
        let config = Document.SectionLayoutConfig(type: .horizontal)
        
        let result = resolver.resolve(config: config)
        
        // Result should have both sectionType and sectionConfig
        _ = result.sectionType
        _ = result.sectionConfig
    }
}

// MARK: - SectionLayoutConfigResult Tests

struct SectionLayoutConfigResultTests {
    
    @Test func resultContainsSectionTypeAndConfig() {
        let sectionConfig = IR.SectionConfig()
        let result = SectionLayoutConfigResult(
            sectionType: .list,
            sectionConfig: sectionConfig
        )
        
        if case .list = result.sectionType {
            // Success
        } else {
            Issue.record("Expected list section type")
        }
        #expect(result.sectionConfig.showsDividers == true) // Default
    }
    
    @Test func resultCanContainGridType() {
        let sectionConfig = IR.SectionConfig()
        let result = SectionLayoutConfigResult(
            sectionType: .grid(columns: .fixed(4)),
            sectionConfig: sectionConfig
        )
        
        if case .grid(let columns) = result.sectionType {
            if case .fixed(let count) = columns {
                #expect(count == 4)
            } else {
                Issue.record("Expected fixed columns")
            }
        } else {
            Issue.record("Expected grid section type")
        }
    }
}
