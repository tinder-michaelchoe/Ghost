//
//  ListLayoutConfigResolver.swift
//  CladsModules
//
//  Resolver for list-style section layouts.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves list-style section layout configurations.
///
/// List layouts display items in a single vertical column with optional dividers.
public struct ListLayoutConfigResolver: SectionLayoutConfigResolving {
    
    public static let layoutType: Document.SectionType = .list
    
    public init() {}
    
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let sectionType = IR.SectionType.list
        
        let sectionConfig = IR.SectionConfig(
            alignment: resolveAlignment(config.alignment),
            itemSpacing: config.itemSpacing ?? 8,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: PaddingConverter.convert(config.contentInsets),
            itemDimensions: resolveItemDimensions(config.itemDimensions),
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: config.isPagingEnabled ?? false,
            snapBehavior: resolveSnapBehavior(config.snapBehavior),
            showsDividers: config.showsDividers ?? true
        )
        
        return SectionLayoutConfigResult(sectionType: sectionType, sectionConfig: sectionConfig)
    }
}

// MARK: - Shared Resolution Helpers

/// Shared helpers for section layout config resolution.
/// These are used by multiple layout resolvers.
public enum SectionLayoutConfigHelpers {
    
    public static func resolveAlignment(_ alignment: Document.SectionAlignment?) -> SwiftUI.HorizontalAlignment {
        switch alignment {
        case .leading, .none:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    public static func resolveItemDimensions(_ dimensions: Document.ItemDimensions?) -> IR.ItemDimensions? {
        guard let dimensions = dimensions else { return nil }
        return IR.ItemDimensions(
            width: resolveDimensionValue(dimensions.width),
            height: resolveDimensionValue(dimensions.height),
            aspectRatio: dimensions.aspectRatio
        )
    }
    
    public static func resolveDimensionValue(_ value: Document.DimensionValue?) -> IR.DimensionValue? {
        guard let value = value else { return nil }
        switch value {
        case .absolute(let v):
            return .absolute(v)
        case .fractional(let v):
            return .fractional(v)
        }
    }
    
    public static func resolveSnapBehavior(_ behavior: Document.SnapBehavior?) -> IR.SnapBehavior {
        guard let behavior = behavior else { return .none }
        switch behavior {
        case .none:
            return .none
        case .viewAligned:
            return .viewAligned
        case .paging:
            return .paging
        }
    }
    
    public static func resolveColumns(_ columns: Document.ColumnConfig?) -> IR.ColumnConfig {
        guard let columns = columns else {
            return .fixed(2)  // Default to 2 columns
        }
        
        switch columns {
        case .fixed(let count):
            return .fixed(count)
        case .adaptive(let minWidth):
            return .adaptive(minWidth: minWidth)
        }
    }
}

// MARK: - Private Extensions

private extension ListLayoutConfigResolver {
    
    func resolveAlignment(_ alignment: Document.SectionAlignment?) -> SwiftUI.HorizontalAlignment {
        SectionLayoutConfigHelpers.resolveAlignment(alignment)
    }
    
    func resolveItemDimensions(_ dimensions: Document.ItemDimensions?) -> IR.ItemDimensions? {
        SectionLayoutConfigHelpers.resolveItemDimensions(dimensions)
    }
    
    func resolveSnapBehavior(_ behavior: Document.SnapBehavior?) -> IR.SnapBehavior {
        SectionLayoutConfigHelpers.resolveSnapBehavior(behavior)
    }
}
