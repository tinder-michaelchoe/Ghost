//
//  ViewNode.swift
//  CladsRendererFramework
//
//  Represents a node in the view tree with dependency tracking.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - View Node

/// A node in the view tree that tracks its state dependencies
public class ViewNode: Identifiable {
    public let id: String
    public let nodeType: ViewNodeType
    public weak var parent: ViewNode?
    public var children: [ViewNode]

    // Dependency tracking
    public var readPaths: Set<String> = []      // State paths this node reads
    public var writePaths: Set<String> = []     // State paths this node writes (e.g., textfield binding)

    // Local state (if this node declares local state)
    public var localState: [String: Any]?

    // Update tracking
    public var needsUpdate: Bool = false
    public var lastUpdateTimestamp: Date?

    public init(
        id: String,
        nodeType: ViewNodeType,
        children: [ViewNode] = []
    ) {
        self.id = id
        self.nodeType = nodeType
        self.children = children

        // Set parent references
        for child in children {
            child.parent = self
        }
    }

    // MARK: - Tree Traversal

    /// Find a node by ID in this subtree
    public func findNode(id: String) -> ViewNode? {
        if self.id == id { return self }
        for child in children {
            if let found = child.findNode(id: id) {
                return found
            }
        }
        return nil
    }

    /// Get all descendant nodes
    public func allDescendants() -> [ViewNode] {
        var result: [ViewNode] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants())
        }
        return result
    }

    /// Get the path from root to this node
    public func pathFromRoot() -> [ViewNode] {
        var path: [ViewNode] = [self]
        var current = self.parent
        while let node = current {
            path.insert(node, at: 0)
            current = node.parent
        }
        return path
    }

    // MARK: - Local State Scope

    /// Find the nearest ancestor (including self) that has local state
    public func nearestLocalStateScope() -> ViewNode? {
        if localState != nil { return self }
        return parent?.nearestLocalStateScope()
    }

    /// Get local state value, walking up the tree if needed
    public func getLocalState(_ path: String) -> Any? {
        // Only look at our own local state (no parent access)
        guard let state = localState else { return nil }
        return StatePathResolver.getValue(from: state, path: path)
    }

    /// Set local state value
    public func setLocalState(_ path: String, value: Any) {
        if localState == nil {
            localState = [:]
        }
        StatePathResolver.setValue(in: &localState!, path: path, value: value)
    }
}

// MARK: - View Node Type

/// The type of a view node
public enum ViewNodeType {
    case root(RootNodeData)
    case container(ContainerNodeData)
    case sectionLayout(SectionLayoutNodeData)
    case section(SectionNodeData)
    case text(TextNodeData)
    case button(ButtonNodeData)
    case textField(TextFieldNodeData)
    case toggle(ToggleNodeData)
    case slider(SliderNodeData)
    case image(ImageNodeData)
    case gradient(GradientNodeData)
    case spacer
}

// MARK: - Node Data Types

public struct RootNodeData {
    public var backgroundColor: String?
    public var colorScheme: RenderColorScheme
    public var style: IR.Style

    public init(backgroundColor: String? = nil, colorScheme: RenderColorScheme = .system, style: IR.Style = IR.Style()) {
        self.backgroundColor = backgroundColor
        self.colorScheme = colorScheme
        self.style = style
    }
}

public struct ContainerNodeData {
    public var layoutType: ContainerNode.LayoutType
    public var alignment: SwiftUI.Alignment
    public var spacing: CGFloat
    public var padding: NSDirectionalEdgeInsets
    public var style: IR.Style

    public init(
        layoutType: ContainerNode.LayoutType = .vstack,
        alignment: SwiftUI.Alignment = .center,
        spacing: CGFloat = 0,
        padding: NSDirectionalEdgeInsets = .zero,
        style: IR.Style = IR.Style()
    ) {
        self.layoutType = layoutType
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.style = style
    }
}

public struct SectionLayoutNodeData {
    public var sectionSpacing: CGFloat

    public init(sectionSpacing: CGFloat = 0) {
        self.sectionSpacing = sectionSpacing
    }
}

public struct SectionNodeData {
    public var layoutType: IR.SectionType
    public var stickyHeader: Bool
    public var config: IR.SectionConfig

    public init(
        layoutType: IR.SectionType = .list,
        stickyHeader: Bool = false,
        config: IR.SectionConfig = IR.SectionConfig()
    ) {
        self.layoutType = layoutType
        self.stickyHeader = stickyHeader
        self.config = config
    }
}

public struct TextNodeData {
    public var content: String
    public var style: IR.Style

    public init(content: String = "", style: IR.Style = IR.Style()) {
        self.content = content
        self.style = style
    }
}

public struct ButtonNodeData {
    public var label: String
    public var style: IR.Style
    public var fillWidth: Bool
    public var onTapAction: Document.Component.ActionBinding?

    public init(
        label: String = "",
        style: IR.Style = IR.Style(),
        fillWidth: Bool = false,
        onTapAction: Document.Component.ActionBinding? = nil
    ) {
        self.label = label
        self.style = style
        self.fillWidth = fillWidth
        self.onTapAction = onTapAction
    }
}

public struct TextFieldNodeData {
    public var placeholder: String
    public var style: IR.Style
    public var bindingPath: String?

    public init(
        placeholder: String = "",
        style: IR.Style = IR.Style(),
        bindingPath: String? = nil
    ) {
        self.placeholder = placeholder
        self.style = style
        self.bindingPath = bindingPath
    }
}

public struct ToggleNodeData {
    public var bindingPath: String?
    public var style: IR.Style

    public init(
        bindingPath: String? = nil,
        style: IR.Style = IR.Style()
    ) {
        self.bindingPath = bindingPath
        self.style = style
    }
}

public struct SliderNodeData {
    public var bindingPath: String?
    public var minValue: Double
    public var maxValue: Double
    public var style: IR.Style

    public init(
        bindingPath: String? = nil,
        minValue: Double = 0.0,
        maxValue: Double = 1.0,
        style: IR.Style = IR.Style()
    ) {
        self.bindingPath = bindingPath
        self.minValue = minValue
        self.maxValue = maxValue
        self.style = style
    }
}

public struct ImageNodeData {
    public var source: ImageNode.Source
    public var style: IR.Style

    public init(source: ImageNode.Source = .system(name: "questionmark"), style: IR.Style = IR.Style()) {
        self.source = source
        self.style = style
    }
}

public struct GradientNodeData {
    public var gradientType: GradientNode.GradientType
    public var colors: [GradientNode.ColorStop]
    public var startPoint: UnitPoint
    public var endPoint: UnitPoint
    public var style: IR.Style

    public init(
        gradientType: GradientNode.GradientType = .linear,
        colors: [GradientNode.ColorStop] = [],
        startPoint: UnitPoint = .top,
        endPoint: UnitPoint = .bottom,
        style: IR.Style = IR.Style()
    ) {
        self.gradientType = gradientType
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.style = style
    }
}

// MARK: - State Path Resolver

/// Utility for resolving dot-notation paths in dictionaries
public enum StatePathResolver {

    public static func getValue(from dict: [String: Any], path: String) -> Any? {
        let components = path.split(separator: ".").map(String.init)
        var current: Any = dict

        for component in components {
            if let dict = current as? [String: Any] {
                guard let next = dict[component] else { return nil }
                current = next
            } else {
                return nil
            }
        }

        return current
    }

    public static func setValue(in dict: inout [String: Any], path: String, value: Any) {
        let components = path.split(separator: ".").map(String.init)

        if components.count == 1 {
            dict[path] = value
            return
        }

        // Navigate to parent, then set
        var current = dict
        for (index, component) in components.dropLast().enumerated() {
            if let next = current[component] as? [String: Any] {
                current = next
            } else {
                // Create intermediate dictionaries
                var newDict: [String: Any] = [:]
                let remainingPath = components[index...].joined(separator: ".")
                setValueRecursive(in: &newDict, components: Array(components[index...]), value: value)
                dict[component] = newDict
                return
            }
        }

        // Set the final value
        setValueRecursive(in: &dict, components: components, value: value)
    }

    private static func setValueRecursive(in dict: inout [String: Any], components: [String], value: Any) {
        guard !components.isEmpty else { return }

        if components.count == 1 {
            dict[components[0]] = value
            return
        }

        let key = components[0]
        var subDict = dict[key] as? [String: Any] ?? [:]
        setValueRecursive(in: &subDict, components: Array(components.dropFirst()), value: value)
        dict[key] = subDict
    }
}
