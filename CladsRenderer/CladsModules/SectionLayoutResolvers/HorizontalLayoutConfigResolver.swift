//
//  HorizontalLayoutConfigResolver.swift
//  CladsModules
//
//  Resolver for horizontal section layouts.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves horizontal section layout configurations.
///
/// Horizontal layouts display items in a scrollable horizontal row.
/// Supports paging, snap behavior, and custom item dimensions.
public struct HorizontalLayoutConfigResolver: SectionLayoutConfigResolving {
    
    public static let layoutType: Document.SectionType = .horizontal
    
    public init() {}
    
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let sectionType = IR.SectionType.horizontal
        
        let sectionConfig = IR.SectionConfig(
            alignment: SectionLayoutConfigHelpers.resolveAlignment(config.alignment),
            itemSpacing: config.itemSpacing ?? 12,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: PaddingConverter.convert(config.contentInsets),
            itemDimensions: SectionLayoutConfigHelpers.resolveItemDimensions(config.itemDimensions),
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: config.isPagingEnabled ?? false,
            snapBehavior: SectionLayoutConfigHelpers.resolveSnapBehavior(config.snapBehavior),
            showsDividers: config.showsDividers ?? false // Horizontal layouts don't use dividers
        )
        
        return SectionLayoutConfigResult(sectionType: sectionType, sectionConfig: sectionConfig)
    }
}
