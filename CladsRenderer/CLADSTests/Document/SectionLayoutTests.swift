//
//  SectionLayoutTests.swift
//  CLADSTests
//
//  Unit tests for Document.SectionLayout JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Basic SectionLayout Tests

struct SectionLayoutBasicTests {
    
    @Test func decodesMinimalSectionLayout() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections.isEmpty)
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesIdProperty() throws {
        let json = """
        {
            "type": "sectionLayout",
            "id": "mainSections",
            "sections": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.id == "mainSections")
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionSpacing() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sectionSpacing": 24,
            "sections": []
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sectionSpacing == 24)
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
}

// MARK: - SectionDefinition Tests

struct SectionDefinitionTests {
    
    @Test func decodesBasicSection() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections.count == 1)
            #expect(sectionLayout.sections[0].layout.type == .list)
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionWithId() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "id": "featuredSection",
                    "layout": { "type": "horizontal" }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections[0].id == "featuredSection")
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionWithHeader() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" },
                    "header": {
                        "type": "label",
                        "text": "Section Header"
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            if case .component(let header) = sectionLayout.sections[0].header {
                #expect(header.text == "Section Header")
            } else {
                Issue.record("Expected header component")
            }
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionWithFooter() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" },
                    "footer": {
                        "type": "label",
                        "text": "Section Footer"
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            if case .component(let footer) = sectionLayout.sections[0].footer {
                #expect(footer.text == "Section Footer")
            } else {
                Issue.record("Expected footer component")
            }
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesStickyHeader() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" },
                    "stickyHeader": true
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections[0].stickyHeader == true)
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionWithStaticChildren() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" },
                    "children": [
                        { "type": "label", "text": "Item 1" },
                        { "type": "label", "text": "Item 2" }
                    ]
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections[0].children?.count == 2)
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
    
    @Test func decodesSectionWithDataSource() throws {
        let json = """
        {
            "type": "sectionLayout",
            "sections": [
                {
                    "layout": { "type": "list" },
                    "dataSource": "items",
                    "itemTemplate": {
                        "type": "label",
                        "text": "${item.name}"
                    }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let sectionLayout) = node {
            #expect(sectionLayout.sections[0].dataSource == "items")
            if case .component = sectionLayout.sections[0].itemTemplate {
                // Success
            } else {
                Issue.record("Expected itemTemplate")
            }
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
}

// MARK: - SectionLayoutConfig Tests

struct SectionLayoutConfigTests {
    
    @Test func decodesHorizontalType() throws {
        let json = """
        { "type": "horizontal" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.type == .horizontal)
    }
    
    @Test func decodesListType() throws {
        let json = """
        { "type": "list" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.type == .list)
    }
    
    @Test func decodesGridType() throws {
        let json = """
        { "type": "grid" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.type == .grid)
    }
    
    @Test func decodesFlowType() throws {
        let json = """
        { "type": "flow" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.type == .flow)
    }
    
    @Test func decodesAlignment() throws {
        let json = """
        { "type": "list", "alignment": "center" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.alignment == .center)
    }
    
    @Test func decodesItemSpacing() throws {
        let json = """
        { "type": "horizontal", "itemSpacing": 12 }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.itemSpacing == 12)
    }
    
    @Test func decodesLineSpacing() throws {
        let json = """
        { "type": "grid", "lineSpacing": 16 }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.lineSpacing == 16)
    }
    
    @Test func decodesContentInsets() throws {
        let json = """
        {
            "type": "list",
            "contentInsets": {
                "horizontal": 16,
                "vertical": 8
            }
        }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.contentInsets?.horizontal == 16)
        #expect(config.contentInsets?.vertical == 8)
    }
    
    @Test func decodesShowsIndicators() throws {
        let json = """
        { "type": "horizontal", "showsIndicators": false }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.showsIndicators == false)
    }
    
    @Test func decodesPagingEnabled() throws {
        let json = """
        { "type": "horizontal", "isPagingEnabled": true }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.isPagingEnabled == true)
    }
    
    @Test func decodesShowsDividers() throws {
        let json = """
        { "type": "list", "showsDividers": true }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.showsDividers == true)
    }
}

// MARK: - SnapBehavior Tests

struct SnapBehaviorTests {
    
    @Test func decodesSnapNone() throws {
        let json = """
        { "type": "horizontal", "snapBehavior": "none" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.snapBehavior == Document.SnapBehavior.none)
    }
    
    @Test func decodesSnapViewAligned() throws {
        let json = """
        { "type": "horizontal", "snapBehavior": "viewAligned" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.snapBehavior == .viewAligned)
    }
    
    @Test func decodesSnapPaging() throws {
        let json = """
        { "type": "horizontal", "snapBehavior": "paging" }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        #expect(config.snapBehavior == .paging)
    }
}

// MARK: - ColumnConfig Tests

struct ColumnConfigTests {
    
    @Test func decodesFixedColumns() throws {
        let json = """
        { "type": "grid", "columns": 3 }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        
        if case .fixed(let count) = config.columns {
            #expect(count == 3)
        } else {
            Issue.record("Expected fixed columns")
        }
    }
    
    @Test func decodesAdaptiveColumns() throws {
        let json = """
        {
            "type": "grid",
            "columns": {
                "adaptive": {
                    "minWidth": 150
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        
        if case .adaptive(let minWidth) = config.columns {
            #expect(minWidth == 150)
        } else {
            Issue.record("Expected adaptive columns")
        }
    }
    
    @Test func columnConfigEquality() {
        let fixed1 = Document.ColumnConfig.fixed(2)
        let fixed2 = Document.ColumnConfig.fixed(2)
        let fixed3 = Document.ColumnConfig.fixed(3)
        let adaptive1 = Document.ColumnConfig.adaptive(minWidth: 100)
        let adaptive2 = Document.ColumnConfig.adaptive(minWidth: 100)
        
        #expect(fixed1 == fixed2)
        #expect(fixed1 != fixed3)
        #expect(adaptive1 == adaptive2)
        #expect(fixed1 != adaptive1)
    }
}

// MARK: - ItemDimensions Tests

struct ItemDimensionsTests {
    
    @Test func decodesAbsoluteWidth() throws {
        let json = """
        {
            "width": 200
        }
        """
        let data = json.data(using: .utf8)!
        let dimensions = try JSONDecoder().decode(Document.ItemDimensions.self, from: data)
        
        if case .absolute(let value) = dimensions.width {
            #expect(value == 200)
        } else {
            Issue.record("Expected absolute width")
        }
    }
    
    @Test func decodesFractionalWidth() throws {
        let json = """
        {
            "width": { "fractional": 0.8 }
        }
        """
        let data = json.data(using: .utf8)!
        let dimensions = try JSONDecoder().decode(Document.ItemDimensions.self, from: data)
        
        if case .fractional(let value) = dimensions.width {
            #expect(value == 0.8)
        } else {
            Issue.record("Expected fractional width")
        }
    }
    
    @Test func decodesExplicitAbsoluteWidth() throws {
        let json = """
        {
            "width": { "absolute": 280 }
        }
        """
        let data = json.data(using: .utf8)!
        let dimensions = try JSONDecoder().decode(Document.ItemDimensions.self, from: data)
        
        if case .absolute(let value) = dimensions.width {
            #expect(value == 280)
        } else {
            Issue.record("Expected absolute width")
        }
    }
    
    @Test func decodesAspectRatio() throws {
        let json = """
        {
            "aspectRatio": 1.5
        }
        """
        let data = json.data(using: .utf8)!
        let dimensions = try JSONDecoder().decode(Document.ItemDimensions.self, from: data)
        #expect(dimensions.aspectRatio == 1.5)
    }
    
    @Test func decodesFullItemDimensions() throws {
        let json = """
        {
            "width": { "fractional": 0.8 },
            "height": { "absolute": 200 },
            "aspectRatio": 1.2
        }
        """
        let data = json.data(using: .utf8)!
        let dimensions = try JSONDecoder().decode(Document.ItemDimensions.self, from: data)
        
        if case .fractional(let w) = dimensions.width {
            #expect(w == 0.8)
        }
        if case .absolute(let h) = dimensions.height {
            #expect(h == 200)
        }
        #expect(dimensions.aspectRatio == 1.2)
    }
}

// MARK: - DimensionValue Tests

struct DimensionValueTests {
    
    @Test func decodesNumberAsAbsolute() throws {
        let json = "150"
        let data = json.data(using: .utf8)!
        let dimension = try JSONDecoder().decode(Document.DimensionValue.self, from: data)
        
        if case .absolute(let value) = dimension {
            #expect(value == 150)
        } else {
            Issue.record("Expected absolute dimension")
        }
    }
    
    @Test func decodesFractionalObject() throws {
        let json = """
        { "fractional": 0.5 }
        """
        let data = json.data(using: .utf8)!
        let dimension = try JSONDecoder().decode(Document.DimensionValue.self, from: data)
        
        if case .fractional(let value) = dimension {
            #expect(value == 0.5)
        } else {
            Issue.record("Expected fractional dimension")
        }
    }
    
    @Test func decodesAbsoluteObject() throws {
        let json = """
        { "absolute": 300 }
        """
        let data = json.data(using: .utf8)!
        let dimension = try JSONDecoder().decode(Document.DimensionValue.self, from: data)
        
        if case .absolute(let value) = dimension {
            #expect(value == 300)
        } else {
            Issue.record("Expected absolute dimension")
        }
    }
    
    @Test func dimensionValueEquality() {
        let abs1 = Document.DimensionValue.absolute(100)
        let abs2 = Document.DimensionValue.absolute(100)
        let abs3 = Document.DimensionValue.absolute(200)
        let frac1 = Document.DimensionValue.fractional(0.5)
        let frac2 = Document.DimensionValue.fractional(0.5)
        
        #expect(abs1 == abs2)
        #expect(abs1 != abs3)
        #expect(frac1 == frac2)
        #expect(abs1 != frac1)
    }
}

// MARK: - Full Section Layout Tests

struct FullSectionLayoutTests {
    
    @Test func decodesComplexSectionLayout() throws {
        let json = """
        {
            "type": "sectionLayout",
            "id": "mainLayout",
            "sectionSpacing": 24,
            "sections": [
                {
                    "id": "featured",
                    "layout": {
                        "type": "horizontal",
                        "itemSpacing": 12,
                        "contentInsets": { "horizontal": 16 },
                        "showsIndicators": false,
                        "snapBehavior": "viewAligned",
                        "itemDimensions": {
                            "width": { "fractional": 0.8 },
                            "aspectRatio": 1.2
                        }
                    },
                    "header": { "type": "label", "text": "Featured" },
                    "children": [
                        { "type": "label", "text": "Item 1" }
                    ]
                },
                {
                    "id": "grid",
                    "layout": {
                        "type": "grid",
                        "columns": { "adaptive": { "minWidth": 150 } },
                        "itemSpacing": 8,
                        "lineSpacing": 8,
                        "contentInsets": { "horizontal": 16 }
                    },
                    "dataSource": "products",
                    "itemTemplate": { "type": "label", "text": "${item.name}" }
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let node = try JSONDecoder().decode(Document.LayoutNode.self, from: data)
        
        if case .sectionLayout(let layout) = node {
            #expect(layout.id == "mainLayout")
            #expect(layout.sectionSpacing == 24)
            #expect(layout.sections.count == 2)
            
            // Featured section
            let featured = layout.sections[0]
            #expect(featured.id == "featured")
            #expect(featured.layout.type == .horizontal)
            #expect(featured.layout.snapBehavior == .viewAligned)
            
            // Grid section
            let grid = layout.sections[1]
            #expect(grid.id == "grid")
            #expect(grid.layout.type == .grid)
            #expect(grid.dataSource == "products")
            
            if case .adaptive(let minWidth) = grid.layout.columns {
                #expect(minWidth == 150)
            }
        } else {
            Issue.record("Expected sectionLayout")
        }
    }
}

// MARK: - Round Trip Tests

struct SectionLayoutRoundTripTests {
    
    @Test func roundTripsSectionLayoutConfig() throws {
        let original = Document.SectionLayoutConfig(
            type: .horizontal,
            alignment: .center,
            itemSpacing: 12,
            showsIndicators: false,
            snapBehavior: .viewAligned
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.SectionLayoutConfig.self, from: data)
        
        #expect(decoded.type == .horizontal)
        #expect(decoded.alignment == .center)
        #expect(decoded.itemSpacing == 12)
        #expect(decoded.showsIndicators == false)
        #expect(decoded.snapBehavior == .viewAligned)
    }
    
    @Test func roundTripsColumnConfig() throws {
        let fixed = Document.ColumnConfig.fixed(3)
        let fixedData = try JSONEncoder().encode(fixed)
        let decodedFixed = try JSONDecoder().decode(Document.ColumnConfig.self, from: fixedData)
        #expect(decodedFixed == fixed)
        
        let adaptive = Document.ColumnConfig.adaptive(minWidth: 120)
        let adaptiveData = try JSONEncoder().encode(adaptive)
        let decodedAdaptive = try JSONDecoder().decode(Document.ColumnConfig.self, from: adaptiveData)
        #expect(decodedAdaptive == adaptive)
    }
}
