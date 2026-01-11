//
//  GridLayoutConfigResolver.swift
//  CladsModules
//
//  Resolver for grid-style section layouts.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves grid-style section layout configurations.
///
/// Grid layouts arrange items in multiple columns, either fixed or adaptive.
public struct GridLayoutConfigResolver: SectionLayoutConfigResolving {
    
    public static let layoutType: Document.SectionType = .grid
    
    public init() {}
    
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let columns = SectionLayoutConfigHelpers.resolveColumns(config.columns)
        let sectionType = IR.SectionType.grid(columns: columns)
        
        let sectionConfig = IR.SectionConfig(
            alignment: SectionLayoutConfigHelpers.resolveAlignment(config.alignment),
            itemSpacing: config.itemSpacing ?? 8,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: PaddingConverter.convert(config.contentInsets),
            itemDimensions: SectionLayoutConfigHelpers.resolveItemDimensions(config.itemDimensions),
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: config.isPagingEnabled ?? false,
            snapBehavior: SectionLayoutConfigHelpers.resolveSnapBehavior(config.snapBehavior),
            showsDividers: config.showsDividers ?? false // Grids typically don't show dividers
        )
        
        return SectionLayoutConfigResult(sectionType: sectionType, sectionConfig: sectionConfig)
    }
}
