//
//  FlowLayoutConfigResolver.swift
//  CladsModules
//
//  Resolver for flow-style section layouts.
//

import CLADS
import Foundation
import SwiftUI

/// Resolves flow-style section layout configurations.
///
/// Flow layouts arrange items horizontally, wrapping to new lines as needed.
/// This is ideal for tags, chips, or variable-width content.
public struct FlowLayoutConfigResolver: SectionLayoutConfigResolving {
    
    public static let layoutType: Document.SectionType = .flow
    
    public init() {}
    
    public func resolve(config: Document.SectionLayoutConfig) -> SectionLayoutConfigResult {
        let sectionType = IR.SectionType.flow
        
        let sectionConfig = IR.SectionConfig(
            alignment: SectionLayoutConfigHelpers.resolveAlignment(config.alignment),
            itemSpacing: config.itemSpacing ?? 8,
            lineSpacing: config.lineSpacing ?? 8,
            contentInsets: PaddingConverter.convert(config.contentInsets),
            itemDimensions: SectionLayoutConfigHelpers.resolveItemDimensions(config.itemDimensions),
            showsIndicators: config.showsIndicators ?? false,
            isPagingEnabled: config.isPagingEnabled ?? false,
            snapBehavior: SectionLayoutConfigHelpers.resolveSnapBehavior(config.snapBehavior),
            showsDividers: config.showsDividers ?? false // Flow layouts don't use dividers
        )
        
        return SectionLayoutConfigResult(sectionType: sectionType, sectionConfig: sectionConfig)
    }
}
