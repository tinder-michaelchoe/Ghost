//
//  GridSectionLayoutRenderer.swift
//  CladsModules
//
//  SwiftUI renderer for grid-style section layouts.
//

import CLADS
import SwiftUI

/// Renders grid-style section layouts in SwiftUI.
///
/// Grid layouts arrange items in multiple columns, either fixed or adaptive.
public struct GridSectionLayoutRenderer: SwiftUISectionLayoutRendering {
    
    public static let layoutTypeIdentifier = SectionLayoutTypeIdentifier.grid
    
    public init() {}
    
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
        guard case .grid(let columns) = section.layoutType else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            GridSectionContentView(section: section, columns: columns, context: context)
        )
    }
}

// MARK: - Grid Section Content View

private struct GridSectionContentView: View {
    let section: IR.Section
    let columns: IR.ColumnConfig
    let context: SwiftUISectionRenderContext
    
    var body: some View {
        let gridColumns: [GridItem] = {
            switch columns {
            case .fixed(let count):
                return Array(repeating: GridItem(.flexible(), spacing: section.config.itemSpacing), count: count)
            case .adaptive(let minWidth):
                return [GridItem(.adaptive(minimum: minWidth), spacing: section.config.itemSpacing)]
            }
        }()
        
        LazyVGrid(columns: gridColumns, spacing: section.config.lineSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { _, child in
                context.renderChild(child)
            }
        }
    }
}
