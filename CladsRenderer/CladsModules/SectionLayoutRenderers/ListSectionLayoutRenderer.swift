//
//  ListSectionLayoutRenderer.swift
//  CladsModules
//
//  SwiftUI renderer for list-style section layouts.
//

import CLADS
import SwiftUI

/// Renders list-style section layouts in SwiftUI.
///
/// List layouts display items in a single vertical column with optional dividers.
public struct ListSectionLayoutRenderer: SwiftUISectionLayoutRendering {
    
    public static let layoutTypeIdentifier = SectionLayoutTypeIdentifier.list
    
    public init() {}
    
    @MainActor
    public func render(section: IR.Section, context: SwiftUISectionRenderContext) -> AnyView {
        AnyView(
            ListSectionContentView(section: section, context: context)
        )
    }
}

// MARK: - List Section Content View

private struct ListSectionContentView: View {
    let section: IR.Section
    let context: SwiftUISectionRenderContext
    
    var body: some View {
        LazyVStack(alignment: section.config.alignment, spacing: section.config.itemSpacing) {
            ForEach(Array(section.children.enumerated()), id: \.offset) { index, child in
                VStack(spacing: 0) {
                    context.renderChild(child)
                        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: section.config.alignment, vertical: .center))
                    if section.config.showsDividers && index < section.children.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}
