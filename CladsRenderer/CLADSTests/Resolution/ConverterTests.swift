//
//  ConverterTests.swift
//  CLADSTests
//
//  Unit tests for Document-to-IR converters.
//

import Foundation
import Testing
import SwiftUI
@testable import CLADS

// MARK: - Alignment Converter Tests

struct AlignmentConverterTests {
    
    // MARK: - VStack Alignment
    
    @Test func convertsLeadingForVStack() {
        let result = AlignmentConverter.forVStack(.leading)
        #expect(result == .leading)
    }
    
    @Test func convertsTrailingForVStack() {
        let result = AlignmentConverter.forVStack(.trailing)
        #expect(result == .trailing)
    }
    
    @Test func convertsCenterForVStack() {
        let result = AlignmentConverter.forVStack(.center)
        #expect(result == .center)
    }
    
    @Test func convertsNilToCenterForVStack() {
        let result = AlignmentConverter.forVStack(nil)
        #expect(result == .center)
    }
    
    // MARK: - HStack Alignment
    
    @Test func convertsTopForHStack() {
        let result = AlignmentConverter.forHStack(.top)
        #expect(result == .top)
    }
    
    @Test func convertsBottomForHStack() {
        let result = AlignmentConverter.forHStack(.bottom)
        #expect(result == .bottom)
    }
    
    @Test func convertsCenterForHStack() {
        let result = AlignmentConverter.forHStack(.center)
        #expect(result == .center)
    }
    
    @Test func convertsNilToCenterForHStack() {
        let result = AlignmentConverter.forHStack(nil)
        #expect(result == .center)
    }
    
    // MARK: - ZStack Alignment
    
    @Test func convertsTopLeadingForZStack() {
        let alignment = Document.Alignment(horizontal: .leading, vertical: .top)
        let result = AlignmentConverter.forZStack(alignment)
        #expect(result == SwiftUI.Alignment(horizontal: .leading, vertical: .top))
    }
    
    @Test func convertsBottomTrailingForZStack() {
        let alignment = Document.Alignment(horizontal: .trailing, vertical: .bottom)
        let result = AlignmentConverter.forZStack(alignment)
        #expect(result == SwiftUI.Alignment(horizontal: .trailing, vertical: .bottom))
    }
    
    @Test func convertsCenterCenterForZStack() {
        let alignment = Document.Alignment(horizontal: .center, vertical: .center)
        let result = AlignmentConverter.forZStack(alignment)
        #expect(result == .center)
    }
    
    @Test func convertsPartialAlignmentForZStack() {
        let alignment = Document.Alignment(horizontal: .trailing, vertical: nil)
        let result = AlignmentConverter.forZStack(alignment)
        #expect(result == SwiftUI.Alignment(horizontal: .trailing, vertical: .center))
    }
    
    @Test func convertsNilToCenterForZStack() {
        let result = AlignmentConverter.forZStack(nil)
        #expect(result == .center)
    }
}

// MARK: - Gradient Point Converter Tests

struct GradientPointConverterTests {
    
    @Test func convertsTopPoint() {
        let result = GradientPointConverter.convert("top")
        #expect(result == .top)
    }
    
    @Test func convertsBottomPoint() {
        let result = GradientPointConverter.convert("bottom")
        #expect(result == .bottom)
    }
    
    @Test func convertsLeadingPoint() {
        let result = GradientPointConverter.convert("leading")
        #expect(result == .leading)
    }
    
    @Test func convertsTrailingPoint() {
        let result = GradientPointConverter.convert("trailing")
        #expect(result == .trailing)
    }
    
    @Test func convertsTopLeadingPoint() {
        let result = GradientPointConverter.convert("topLeading")
        #expect(result == .topLeading)
    }
    
    @Test func convertsTopTrailingPoint() {
        let result = GradientPointConverter.convert("topTrailing")
        #expect(result == .topTrailing)
    }
    
    @Test func convertsBottomLeadingPoint() {
        let result = GradientPointConverter.convert("bottomLeading")
        #expect(result == .bottomLeading)
    }
    
    @Test func convertsBottomTrailingPoint() {
        let result = GradientPointConverter.convert("bottomTrailing")
        #expect(result == .bottomTrailing)
    }
    
    @Test func convertsCenterPoint() {
        let result = GradientPointConverter.convert("center")
        #expect(result == .center)
    }
    
    @Test func convertsNilToDefaultBottom() {
        let result = GradientPointConverter.convert(nil)
        #expect(result == .bottom)
    }
    
    @Test func convertsUnknownToDefaultBottom() {
        let result = GradientPointConverter.convert("unknown")
        #expect(result == .bottom)
    }
    
    @Test func isCaseInsensitive() {
        #expect(GradientPointConverter.convert("TOP") == .top)
        #expect(GradientPointConverter.convert("Bottom") == .bottom)
        #expect(GradientPointConverter.convert("TOPLEADING") == .topLeading)
    }
}

// MARK: - Padding Converter Tests

struct PaddingConverterTests {
    
    @Test func convertsNilToZero() {
        let result = PaddingConverter.convert(nil)
        #expect(result == .zero)
    }
    
    @Test func convertsAllEdges() {
        let padding = Document.Padding(top: 10, bottom: 20, leading: 5, trailing: 15)
        let result = PaddingConverter.convert(padding)
        
        #expect(result.top == 10)
        #expect(result.bottom == 20)
        #expect(result.leading == 5)
        #expect(result.trailing == 15)
    }
    
    @Test func convertsHorizontalPadding() {
        let padding = Document.Padding(horizontal: 16)
        let result = PaddingConverter.convert(padding)
        
        #expect(result.leading == 16)
        #expect(result.trailing == 16)
        #expect(result.top == 0)
        #expect(result.bottom == 0)
    }
    
    @Test func convertsVerticalPadding() {
        let padding = Document.Padding(vertical: 12)
        let result = PaddingConverter.convert(padding)
        
        #expect(result.top == 12)
        #expect(result.bottom == 12)
        #expect(result.leading == 0)
        #expect(result.trailing == 0)
    }
    
    @Test func prefersSpecificOverGeneral() {
        let padding = Document.Padding(top: 5, horizontal: 16, vertical: 12)
        let result = PaddingConverter.convert(padding)
        
        // Specific top should override vertical
        #expect(result.top == 5)
        // Vertical should apply to bottom
        #expect(result.bottom == 12)
        // Horizontal should apply to leading/trailing
        #expect(result.leading == 16)
        #expect(result.trailing == 16)
    }
}

// MARK: - Color Scheme Converter Tests

struct ColorSchemeConverterTests {
    
    @Test func convertsLightScheme() {
        let result = ColorSchemeConverter.convert("light")
        #expect(result == .light)
    }
    
    @Test func convertsDarkScheme() {
        let result = ColorSchemeConverter.convert("dark")
        #expect(result == .dark)
    }
    
    @Test func convertsNilToSystem() {
        let result = ColorSchemeConverter.convert(nil)
        #expect(result == .system)
    }
    
    @Test func convertsUnknownToSystem() {
        let result = ColorSchemeConverter.convert("unknown")
        #expect(result == .system)
    }
    
    @Test func isCaseInsensitive() {
        #expect(ColorSchemeConverter.convert("LIGHT") == .light)
        #expect(ColorSchemeConverter.convert("Dark") == .dark)
        #expect(ColorSchemeConverter.convert("DARK") == .dark)
    }
}

// MARK: - State Value Converter Tests

struct StateValueConverterTests {
    
    // MARK: - Unwrap Tests
    
    @Test func unwrapsIntValue() {
        let value = Document.StateValue.intValue(42)
        let result = StateValueConverter.unwrap(value)
        #expect(result as? Int == 42)
    }
    
    @Test func unwrapsDoubleValue() {
        let value = Document.StateValue.doubleValue(3.14)
        let result = StateValueConverter.unwrap(value)
        #expect(result as? Double == 3.14)
    }
    
    @Test func unwrapsStringValue() {
        let value = Document.StateValue.stringValue("hello")
        let result = StateValueConverter.unwrap(value)
        #expect(result as? String == "hello")
    }
    
    @Test func unwrapsBoolValue() {
        let value = Document.StateValue.boolValue(true)
        let result = StateValueConverter.unwrap(value)
        #expect(result as? Bool == true)
    }
    
    @Test func unwrapsNullValue() {
        let value = Document.StateValue.nullValue
        let result = StateValueConverter.unwrap(value)
        #expect(result is NSNull)
    }
    
    @Test func unwrapsArrayValue() {
        let value = Document.StateValue.arrayValue([.intValue(1), .intValue(2), .intValue(3)])
        let result = StateValueConverter.unwrap(value)
        let array = result as? [Any]
        #expect(array?.count == 3)
        #expect(array?[0] as? Int == 1)
        #expect(array?[1] as? Int == 2)
        #expect(array?[2] as? Int == 3)
    }
    
    @Test func unwrapsObjectValue() {
        let value = Document.StateValue.objectValue([
            "name": .stringValue("test"),
            "count": .intValue(5)
        ])
        let result = StateValueConverter.unwrap(value)
        let dict = result as? [String: Any]
        #expect(dict?["name"] as? String == "test")
        #expect(dict?["count"] as? Int == 5)
    }
    
    // MARK: - Any to StateValue Tests
    
    @Test func convertsIntToStateValue() {
        let result = StateValueConverter.anyToStateValue(42)
        #expect(result == .intValue(42))
    }
    
    @Test func convertsDoubleToStateValue() {
        let result = StateValueConverter.anyToStateValue(3.14)
        #expect(result == .doubleValue(3.14))
    }
    
    @Test func convertsStringToStateValue() {
        let result = StateValueConverter.anyToStateValue("hello")
        #expect(result == .stringValue("hello"))
    }
    
    @Test func convertsBoolToStateValue() {
        let result = StateValueConverter.anyToStateValue(true)
        #expect(result == .boolValue(true))
    }
    
    @Test func convertsArrayToStateValue() {
        let result = StateValueConverter.anyToStateValue([1, 2, 3])
        if case .arrayValue(let arr) = result {
            #expect(arr.count == 3)
            #expect(arr[0] == .intValue(1))
        } else {
            Issue.record("Expected array value")
        }
    }
    
    @Test func convertsDictToStateValue() {
        let result = StateValueConverter.anyToStateValue(["key": "value"])
        if case .objectValue(let obj) = result {
            #expect(obj["key"] == .stringValue("value"))
        } else {
            Issue.record("Expected object value")
        }
    }
    
    @Test func convertsUnknownToNull() {
        // Something that's not directly convertible
        class CustomClass {}
        let result = StateValueConverter.anyToStateValue(CustomClass())
        #expect(result == .nullValue)
    }
    
    // MARK: - ToSetValue Tests
    
    @Test func convertsNilToNullLiteral() {
        let result = StateValueConverter.toSetValue(nil)
        if case .literal(.nullValue) = result {
            // Success
        } else {
            Issue.record("Expected null literal")
        }
    }
    
    @Test func convertsExpressionDict() {
        let dict: [String: Any] = ["$expr": "counter + 1"]
        let result = StateValueConverter.toSetValue(dict)
        if case .expression(let expr) = result {
            #expect(expr == "counter + 1")
        } else {
            Issue.record("Expected expression")
        }
    }
    
    @Test func convertsValueToLiteral() {
        let result = StateValueConverter.toSetValue(42)
        if case .literal(.intValue(let v)) = result {
            #expect(v == 42)
        } else {
            Issue.record("Expected int literal")
        }
    }
}
