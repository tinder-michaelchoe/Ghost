//
//  Converters.swift
//  CladsRendererFramework
//
//  Value converters for transforming schema types to IR types.
//

import Foundation
import SwiftUI

// MARK: - Alignment Converter

/// Converts schema alignment types to SwiftUI.Alignment
public enum AlignmentConverter {

    /// Converts horizontal alignment for VStack
    public static func forVStack(_ alignment: Document.HorizontalAlignment?) -> SwiftUI.Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center, .none: return .center
        }
    }

    /// Converts vertical alignment for HStack
    public static func forHStack(_ alignment: Document.VerticalAlignment?) -> SwiftUI.Alignment {
        switch alignment {
        case .top: return .top
        case .bottom: return .bottom
        case .center, .none: return .center
        }
    }

    /// Converts 2D alignment for ZStack
    public static func forZStack(_ alignment: Document.Alignment?) -> SwiftUI.Alignment {
        guard let alignment = alignment else { return .center }

        let h: SwiftUI.HorizontalAlignment
        let v: SwiftUI.VerticalAlignment

        switch alignment.horizontal {
        case .leading: h = .leading
        case .trailing: h = .trailing
        case .center, .none: h = .center
        }

        switch alignment.vertical {
        case .top: v = .top
        case .bottom: v = .bottom
        case .center, .none: v = .center
        }

        return SwiftUI.Alignment(horizontal: h, vertical: v)
    }
}

// MARK: - Gradient Point Converter

/// Converts gradient point strings to UnitPoint
public enum GradientPointConverter {

    /// Converts a named point string to UnitPoint
    /// - Parameter point: Named point like "top", "bottomLeading", etc.
    /// - Returns: Corresponding UnitPoint, defaults to .bottom
    public static func convert(_ point: String?) -> UnitPoint {
        switch point?.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "topleading": return .topLeading
        case "toptrailing": return .topTrailing
        case "bottomleading": return .bottomLeading
        case "bottomtrailing": return .bottomTrailing
        case "center": return .center
        default: return .bottom
        }
    }
}

// MARK: - Padding Converter

/// Converts schema Padding to NSDirectionalEdgeInsets
public enum PaddingConverter {

    /// Converts optional Padding to NSDirectionalEdgeInsets
    public static func convert(_ padding: Document.Padding?) -> NSDirectionalEdgeInsets {
        guard let padding = padding else { return .zero }
        return NSDirectionalEdgeInsets(
            top: padding.resolvedTop,
            leading: padding.resolvedLeading,
            bottom: padding.resolvedBottom,
            trailing: padding.resolvedTrailing
        )
    }
}

// MARK: - Color Scheme Converter

/// Converts color scheme strings to RenderColorScheme
public enum ColorSchemeConverter {

    /// Converts a color scheme string to RenderColorScheme
    public static func convert(_ scheme: String?) -> RenderColorScheme {
        switch scheme?.lowercased() {
        case "light": return .light
        case "dark": return .dark
        default: return .system
        }
    }
}

// MARK: - State Value Converter

/// Converts StateValue enum to native Swift types
public enum StateValueConverter {

    /// Unwraps a StateValue to its underlying Swift type
    public static func unwrap(_ value: Document.StateValue) -> Any {
        switch value {
        case .intValue(let v): return v
        case .doubleValue(let v): return v
        case .stringValue(let v): return v
        case .boolValue(let v): return v
        case .nullValue: return NSNull()
        }
    }

    /// Converts a value to StateSetValue for action resolution
    public static func toSetValue(_ value: Any?) -> StateSetValue {
        guard let value = value else { return .literal(.nullValue) }

        if let dict = value as? [String: Any],
           let expr = dict["$expr"] as? String {
            return .expression(expr)
        }

        // Convert to StateValue
        let stateValue = anyToStateValue(value)
        return .literal(stateValue)
    }

    /// Converts an Any value to StateValue
    public static func anyToStateValue(_ value: Any) -> Document.StateValue {
        if let intVal = value as? Int {
            return .intValue(intVal)
        } else if let doubleVal = value as? Double {
            return .doubleValue(doubleVal)
        } else if let stringVal = value as? String {
            return .stringValue(stringVal)
        } else if let boolVal = value as? Bool {
            return .boolValue(boolVal)
        } else {
            return .nullValue
        }
    }
}
