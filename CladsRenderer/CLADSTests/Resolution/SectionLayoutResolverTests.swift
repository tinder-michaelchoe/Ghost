//
//  SectionLayoutResolverTests.swift
//  CLADSTests
//
//  Unit tests for SectionLayoutResolver - section types and configuration resolution.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Basic Section Layout Tests

struct SectionLayoutResolverBasicTests {
    
    @Test @MainActor func resolvesEmptySectionLayout() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: []
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections.isEmpty)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesSectionLayoutWithId() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            id: "main-sections",
            sections: []
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.id == "main-sections")
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesSectionSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sectionSpacing: 24,
            sections: []
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sectionSpacing == 24)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesDefaultSectionSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: []
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sectionSpacing == 0)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Section Type Resolution Tests

struct SectionLayoutResolverTypeTests {
    
    @Test @MainActor func resolvesHorizontalSection() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .horizontal),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections.count == 1)
            if case .horizontal = node.sections[0].layoutType {
                // Success
            } else {
                Issue.record("Expected horizontal section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesListSection() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .list = node.sections[0].layoutType {
                // Success
            } else {
                Issue.record("Expected list section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesGridSectionWithFixedColumns() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .grid,
                        columns: .fixed(3)
                    ),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .grid(let columns) = node.sections[0].layoutType {
                if case .fixed(let count) = columns {
                    #expect(count == 3)
                } else {
                    Issue.record("Expected fixed columns")
                }
            } else {
                Issue.record("Expected grid section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesGridSectionWithAdaptiveColumns() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .grid,
                        columns: .adaptive(minWidth: 120)
                    ),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .grid(let columns) = node.sections[0].layoutType {
                if case .adaptive(let minWidth) = columns {
                    #expect(minWidth == 120)
                } else {
                    Issue.record("Expected adaptive columns")
                }
            } else {
                Issue.record("Expected grid section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesGridSectionWithDefaultColumns() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .grid),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .grid(let columns) = node.sections[0].layoutType {
                if case .fixed(let count) = columns {
                    #expect(count == 2) // Default is 2 columns
                } else {
                    Issue.record("Expected fixed columns as default")
                }
            } else {
                Issue.record("Expected grid section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesFlowSection() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .flow),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .flow = node.sections[0].layoutType {
                // Success
            } else {
                Issue.record("Expected flow section type")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Section Config Resolution Tests

struct SectionLayoutResolverConfigTests {
    
    @Test @MainActor func resolvesItemSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list, itemSpacing: 12),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.itemSpacing == 12)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesLineSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .grid, lineSpacing: 16),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.lineSpacing == 16)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesDefaultSpacing() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.itemSpacing == 8) // Default
            #expect(node.sections[0].config.lineSpacing == 8) // Default
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesContentInsets() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .horizontal,
                        contentInsets: Document.Padding(horizontal: 16, vertical: 8)
                    ),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.contentInsets.leading == 16)
            #expect(node.sections[0].config.contentInsets.trailing == 16)
            #expect(node.sections[0].config.contentInsets.top == 8)
            #expect(node.sections[0].config.contentInsets.bottom == 8)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesShowsIndicators() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .horizontal, showsIndicators: true),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.showsIndicators == true)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesShowsDividers() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list, showsDividers: false),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.showsDividers == false)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesDefaultShowsDividers() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.showsDividers == true) // Default is true
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Snap Behavior Tests

struct SectionLayoutResolverSnapBehaviorTests {
    
    @Test @MainActor func resolvesSnapBehaviorNone() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .horizontal,
                        snapBehavior: Document.SnapBehavior.none
                    ),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.snapBehavior == IR.SnapBehavior.none)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesSnapBehaviorViewAligned() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .horizontal,
                        snapBehavior: .viewAligned
                    ),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.snapBehavior == .viewAligned)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesSnapBehaviorPaging() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(
                        type: .horizontal,
                        snapBehavior: .paging
                    ),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.snapBehavior == .paging)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Section Header/Footer Tests

struct SectionLayoutResolverHeaderFooterTests {
    
    @Test @MainActor func resolvesSectionWithHeader() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    header: .spacer,
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].header != nil)
            if case .spacer = node.sections[0].header {
                // Success
            } else {
                Issue.record("Expected spacer header")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesSectionWithFooter() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    footer: .spacer,
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].footer != nil)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesStickyHeader() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    header: .spacer,
                    stickyHeader: true,
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].stickyHeader == true)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesNonStickyHeaderByDefault() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    header: .spacer,
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].stickyHeader == false)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Multiple Sections Tests

struct SectionLayoutResolverMultipleSectionsTests {
    
    @Test @MainActor func resolvesMultipleSections() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    id: "section1",
                    layout: Document.SectionLayoutConfig(type: .horizontal),
                    children: [.spacer]
                ),
                Document.SectionDefinition(
                    id: "section2",
                    layout: Document.SectionLayoutConfig(type: .grid),
                    children: [.spacer, .spacer]
                ),
                Document.SectionDefinition(
                    id: "section3",
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: [.spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections.count == 3)
            #expect(node.sections[0].id == "section1")
            #expect(node.sections[1].id == "section2")
            #expect(node.sections[2].id == "section3")
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesMixedSectionTypes() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .horizontal),
                    children: []
                ),
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: []
                ),
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .flow),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            if case .horizontal = node.sections[0].layoutType { } else { Issue.record("Expected horizontal") }
            if case .list = node.sections[1].layoutType { } else { Issue.record("Expected list") }
            if case .flow = node.sections[2].layoutType { } else { Issue.record("Expected flow") }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Section Children Tests

struct SectionLayoutResolverChildrenTests {
    
    @Test @MainActor func resolvesStaticChildren() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: [.spacer, .spacer, .spacer]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].children.count == 3)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesEmptyChildren() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].children.isEmpty)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesNestedLayoutChildren() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list),
                    children: [
                        .layout(Document.Layout(type: .hstack, children: [.spacer]))
                    ]
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].children.count == 1)
            if case .container(let container) = node.sections[0].children[0] {
                #expect(container.layoutType == .hstack)
            } else {
                Issue.record("Expected container child")
            }
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}

// MARK: - Section Alignment Tests

struct SectionLayoutResolverAlignmentTests {
    
    @Test @MainActor func resolvesLeadingAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list, alignment: .leading),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.alignment == .leading)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesCenterAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list, alignment: .center),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.alignment == .center)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
    
    @Test @MainActor func resolvesTrailingAlignment() throws {
        let registry = ComponentResolverRegistry()
        let resolver = SectionLayoutResolver(componentRegistry: registry)
        let context = createTestContext()
        
        let sectionLayout = Document.SectionLayout(
            sections: [
                Document.SectionDefinition(
                    layout: Document.SectionLayoutConfig(type: .list, alignment: .trailing),
                    children: []
                )
            ]
        )
        
        let result = try resolver.resolve(sectionLayout, context: context)
        
        if case .sectionLayout(let node) = result.renderNode {
            #expect(node.sections[0].config.alignment == .trailing)
        } else {
            Issue.record("Expected sectionLayout node")
        }
    }
}
