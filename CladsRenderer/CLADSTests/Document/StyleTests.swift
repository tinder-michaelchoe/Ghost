//
//  StyleTests.swift
//  CLADSTests
//
//  Unit tests for Document.Style JSON parsing.
//

import Foundation
import Testing
@testable import CLADS

// MARK: - Typography Tests

struct StyleTypographyTests {
    
    @Test func decodesFontFamily() throws {
        let json = """
        { "fontFamily": "Helvetica" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontFamily == "Helvetica")
    }
    
    @Test func decodesFontSize() throws {
        let json = """
        { "fontSize": 16.5 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontSize == 16.5)
    }
    
    @Test func decodesTextColor() throws {
        let json = """
        { "textColor": "#FF0000" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.textColor == "#FF0000")
    }
}

// MARK: - Font Weight Tests

struct StyleFontWeightTests {
    
    @Test func decodesUltraLightWeight() throws {
        let json = """
        { "fontWeight": "ultraLight" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .ultraLight)
    }
    
    @Test func decodesThinWeight() throws {
        let json = """
        { "fontWeight": "thin" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .thin)
    }
    
    @Test func decodesLightWeight() throws {
        let json = """
        { "fontWeight": "light" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .light)
    }
    
    @Test func decodesRegularWeight() throws {
        let json = """
        { "fontWeight": "regular" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .regular)
    }
    
    @Test func decodesMediumWeight() throws {
        let json = """
        { "fontWeight": "medium" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .medium)
    }
    
    @Test func decodesSemiboldWeight() throws {
        let json = """
        { "fontWeight": "semibold" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .semibold)
    }
    
    @Test func decodesBoldWeight() throws {
        let json = """
        { "fontWeight": "bold" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .bold)
    }
    
    @Test func decodesHeavyWeight() throws {
        let json = """
        { "fontWeight": "heavy" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .heavy)
    }
    
    @Test func decodesBlackWeight() throws {
        let json = """
        { "fontWeight": "black" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontWeight == .black)
    }
}

// MARK: - Text Alignment Tests

struct StyleTextAlignmentTests {
    
    @Test func decodesLeadingAlignment() throws {
        let json = """
        { "textAlignment": "leading" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.textAlignment == .leading)
    }
    
    @Test func decodesCenterAlignment() throws {
        let json = """
        { "textAlignment": "center" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.textAlignment == .center)
    }
    
    @Test func decodesTrailingAlignment() throws {
        let json = """
        { "textAlignment": "trailing" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.textAlignment == .trailing)
    }
}

// MARK: - Background & Border Tests

struct StyleBackgroundBorderTests {
    
    @Test func decodesBackgroundColor() throws {
        let json = """
        { "backgroundColor": "#FFFFFF" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.backgroundColor == "#FFFFFF")
    }
    
    @Test func decodesCornerRadius() throws {
        let json = """
        { "cornerRadius": 12 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.cornerRadius == 12)
    }
    
    @Test func decodesBorderWidth() throws {
        let json = """
        { "borderWidth": 2 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.borderWidth == 2)
    }
    
    @Test func decodesBorderColor() throws {
        let json = """
        { "borderColor": "#000000" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.borderColor == "#000000")
    }
    
    @Test func decodesTintColor() throws {
        let json = """
        { "tintColor": "#007AFF" }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.tintColor == "#007AFF")
    }
}

// MARK: - Sizing Tests

struct StyleSizingTests {
    
    @Test func decodesWidth() throws {
        let json = """
        { "width": 100 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.width == 100)
    }
    
    @Test func decodesHeight() throws {
        let json = """
        { "height": 50 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.height == 50)
    }
    
    @Test func decodesMinWidth() throws {
        let json = """
        { "minWidth": 80 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.minWidth == 80)
    }
    
    @Test func decodesMinHeight() throws {
        let json = """
        { "minHeight": 40 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.minHeight == 40)
    }
    
    @Test func decodesMaxWidth() throws {
        let json = """
        { "maxWidth": 300 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.maxWidth == 300)
    }
    
    @Test func decodesMaxHeight() throws {
        let json = """
        { "maxHeight": 200 }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.maxHeight == 200)
    }
    
    @Test func decodesAllSizingProperties() throws {
        let json = """
        {
            "width": 100,
            "height": 50,
            "minWidth": 80,
            "minHeight": 40,
            "maxWidth": 200,
            "maxHeight": 100
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.width == 100)
        #expect(style.height == 50)
        #expect(style.minWidth == 80)
        #expect(style.minHeight == 40)
        #expect(style.maxWidth == 200)
        #expect(style.maxHeight == 100)
    }
}

// MARK: - Padding Tests

struct StylePaddingTests {
    
    @Test func decodesIndividualPadding() throws {
        let json = """
        {
            "padding": {
                "top": 10,
                "bottom": 20,
                "leading": 15,
                "trailing": 15
            }
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.padding?.top == 10)
        #expect(style.padding?.bottom == 20)
        #expect(style.padding?.leading == 15)
        #expect(style.padding?.trailing == 15)
    }
    
    @Test func decodesHorizontalPadding() throws {
        let json = """
        {
            "padding": {
                "horizontal": 20
            }
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.padding?.horizontal == 20)
    }
    
    @Test func decodesVerticalPadding() throws {
        let json = """
        {
            "padding": {
                "vertical": 16
            }
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.padding?.vertical == 16)
    }
    
    @Test func decodesMixedPadding() throws {
        let json = """
        {
            "padding": {
                "horizontal": 20,
                "vertical": 16
            }
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.padding?.horizontal == 20)
        #expect(style.padding?.vertical == 16)
    }
    
    @Test func paddingResolvedValues() {
        let padding = Document.Padding(
            top: nil,
            bottom: 10,
            leading: nil,
            trailing: nil,
            horizontal: 20,
            vertical: 16
        )
        
        #expect(padding.resolvedTop == 16)      // Falls back to vertical
        #expect(padding.resolvedBottom == 10)   // Uses specific value
        #expect(padding.resolvedLeading == 20)  // Falls back to horizontal
        #expect(padding.resolvedTrailing == 20) // Falls back to horizontal
    }
    
    @Test func paddingResolvedValuesWithAllZeros() {
        let padding = Document.Padding()
        
        #expect(padding.resolvedTop == 0)
        #expect(padding.resolvedBottom == 0)
        #expect(padding.resolvedLeading == 0)
        #expect(padding.resolvedTrailing == 0)
    }
}

// MARK: - Inheritance Tests

struct StyleInheritanceTests {
    
    @Test func decodesInheritsField() throws {
        let json = """
        {
            "inherits": "baseStyle",
            "fontSize": 18
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.inherits == "baseStyle")
        #expect(style.fontSize == 18)
    }
    
    @Test func decodesStyleWithoutInheritance() throws {
        let json = """
        {
            "fontSize": 16,
            "fontWeight": "regular"
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.inherits == nil)
    }
}

// MARK: - Partial Style Tests

struct StylePartialTests {
    
    @Test func decodesEmptyStyle() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontFamily == nil)
        #expect(style.fontSize == nil)
        #expect(style.fontWeight == nil)
        #expect(style.textColor == nil)
        #expect(style.backgroundColor == nil)
    }
    
    @Test func decodesStyleWithOnlyTypography() throws {
        let json = """
        {
            "fontFamily": "SF Pro",
            "fontSize": 14,
            "fontWeight": "medium",
            "textColor": "#333333",
            "textAlignment": "center"
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.fontFamily == "SF Pro")
        #expect(style.fontSize == 14)
        #expect(style.fontWeight == .medium)
        #expect(style.textColor == "#333333")
        #expect(style.textAlignment == .center)
        #expect(style.backgroundColor == nil)
        #expect(style.width == nil)
    }
    
    @Test func decodesStyleWithOnlySizing() throws {
        let json = """
        {
            "width": 200,
            "height": 44
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        #expect(style.width == 200)
        #expect(style.height == 44)
        #expect(style.fontSize == nil)
    }
}

// MARK: - Full Style Tests

struct StyleFullTests {
    
    @Test func decodesFullStyle() throws {
        let json = """
        {
            "inherits": "baseStyle",
            "fontFamily": "Helvetica Neue",
            "fontSize": 16,
            "fontWeight": "semibold",
            "textColor": "#000000",
            "textAlignment": "leading",
            "backgroundColor": "#FFFFFF",
            "cornerRadius": 8,
            "borderWidth": 1,
            "borderColor": "#CCCCCC",
            "tintColor": "#007AFF",
            "width": 200,
            "height": 44,
            "minWidth": 100,
            "minHeight": 30,
            "maxWidth": 400,
            "maxHeight": 60,
            "padding": {
                "horizontal": 16,
                "vertical": 12
            }
        }
        """
        let data = json.data(using: .utf8)!
        let style = try JSONDecoder().decode(Document.Style.self, from: data)
        
        #expect(style.inherits == "baseStyle")
        #expect(style.fontFamily == "Helvetica Neue")
        #expect(style.fontSize == 16)
        #expect(style.fontWeight == .semibold)
        #expect(style.textColor == "#000000")
        #expect(style.textAlignment == .leading)
        #expect(style.backgroundColor == "#FFFFFF")
        #expect(style.cornerRadius == 8)
        #expect(style.borderWidth == 1)
        #expect(style.borderColor == "#CCCCCC")
        #expect(style.tintColor == "#007AFF")
        #expect(style.width == 200)
        #expect(style.height == 44)
        #expect(style.minWidth == 100)
        #expect(style.minHeight == 30)
        #expect(style.maxWidth == 400)
        #expect(style.maxHeight == 60)
        #expect(style.padding?.horizontal == 16)
        #expect(style.padding?.vertical == 12)
    }
}

// MARK: - Style Dictionary Tests

struct StyleDictionaryTests {
    
    @Test func decodesStylesDictionary() throws {
        let json = """
        {
            "titleStyle": {
                "fontSize": 24,
                "fontWeight": "bold"
            },
            "bodyStyle": {
                "fontSize": 16,
                "fontWeight": "regular"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let styles = try JSONDecoder().decode([String: Document.Style].self, from: data)
        
        #expect(styles.count == 2)
        #expect(styles["titleStyle"]?.fontSize == 24)
        #expect(styles["titleStyle"]?.fontWeight == .bold)
        #expect(styles["bodyStyle"]?.fontSize == 16)
        #expect(styles["bodyStyle"]?.fontWeight == .regular)
    }
}

// MARK: - Round Trip Tests

struct StyleRoundTripTests {
    
    @Test func roundTripsStyle() throws {
        let original = Document.Style(
            fontFamily: "System",
            fontSize: 16,
            fontWeight: .medium,
            textColor: "#333333",
            backgroundColor: "#FFFFFF",
            cornerRadius: 8
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Document.Style.self, from: data)
        
        #expect(decoded.fontFamily == original.fontFamily)
        #expect(decoded.fontSize == original.fontSize)
        #expect(decoded.fontWeight == original.fontWeight)
        #expect(decoded.textColor == original.textColor)
        #expect(decoded.backgroundColor == original.backgroundColor)
        #expect(decoded.cornerRadius == original.cornerRadius)
    }
}
