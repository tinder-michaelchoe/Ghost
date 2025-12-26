//
//  DocumentDebugDescription.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Document Debug Description

extension Document: CustomDebugStringConvertible {
    public var debugDescription: String {
        var lines: [String] = []

        lines.append("Document: \(id)")
        if let version = version {
            lines.append("Version: \(version)")
        }

        // State
        if let state = state, !state.isEmpty {
            lines.append("")
            lines.append("State:")
            for (key, value) in state.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(key): \(value.debugValue)")
            }
        }

        // Styles (as inheritance tree)
        if let styles = styles, !styles.isEmpty {
            lines.append("")
            lines.append("Styles:")
            lines.append(contentsOf: buildStyleTree(styles))
        }

        // Data Sources
        if let dataSources = dataSources, !dataSources.isEmpty {
            lines.append("")
            lines.append("Data Sources:")
            for (key, source) in dataSources.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(key): \(source.debugValue)")
            }
        }

        // Actions
        if let actions = actions, !actions.isEmpty {
            lines.append("")
            lines.append("Actions:")
            for (key, action) in actions.sorted(by: { $0.key < $1.key }) {
                let type = action["type"] as? String ?? "unknown"
                lines.append("  \(key): \(type)")
            }
        }

        // Root Component Tree
        lines.append("")
        lines.append("Component Tree:")
        lines.append(root.debugDescription(indent: 1))

        return lines.joined(separator: "\n")
    }

    /// Build a tree representation of style inheritance
    private func buildStyleTree(_ styles: [String: Style]) -> [String] {
        var lines: [String] = []

        // Build parent -> children map
        var children: [String: [String]] = [:]
        var rootStyles: [String] = []

        for (styleId, style) in styles {
            if let parentId = style.inherits {
                children[parentId, default: []].append(styleId)
            } else {
                rootStyles.append(styleId)
            }
        }

        // Sort for consistent output
        rootStyles.sort()
        for key in children.keys {
            children[key]?.sort()
        }

        // Recursively print tree
        func printStyle(_ styleId: String, indent: Int, isLast: Bool, prefix: String) {
            let connector = isLast ? "└── " : "├── "
            let newPrefix = prefix + (isLast ? "    " : "│   ")

            lines.append(prefix + connector + styleId)

            let styleChildren = children[styleId] ?? []
            for (index, childId) in styleChildren.enumerated() {
                let childIsLast = index == styleChildren.count - 1
                printStyle(childId, indent: indent + 1, isLast: childIsLast, prefix: newPrefix)
            }
        }

        // Print each root style
        for (index, styleId) in rootStyles.enumerated() {
            let isLast = index == rootStyles.count - 1
            printStyle(styleId, indent: 0, isLast: isLast, prefix: "  ")
        }

        return lines
    }
}

// MARK: - RootComponent Debug

extension RootComponent {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var rootDesc = "root"
        var props: [String] = []
        if let bg = backgroundColor { props.append("bg: \(bg)") }
        if let styleId = styleId { props.append("style: \(styleId)") }
        if edgeInsets != nil { props.append("edgeInsets") }
        if !props.isEmpty {
            rootDesc += " (\(props.joined(separator: ", ")))"
        }
        lines.append(prefix + rootDesc)

        for child in children {
            lines.append(child.debugDescription(indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - LayoutNode Debug

extension LayoutNode {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        switch self {
        case .layout(let layout):
            return layout.debugDescription(indent: indent)
        case .component(let component):
            return component.debugDescription(indent: indent)
        case .spacer:
            return prefix + "spacer"
        }
    }
}

// MARK: - Layout Debug

extension Layout {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var desc = type.rawValue
        var props: [String] = []
        if let spacing = spacing { props.append("spacing: \(Int(spacing))") }
        if let align = horizontalAlignment { props.append("align: \(align.rawValue)") }
        if !props.isEmpty {
            desc += " (\(props.joined(separator: ", ")))"
        }
        lines.append(prefix + desc)

        for child in children {
            lines.append(child.debugDescription(indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Component Debug

extension Component {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        var desc = type.rawValue
        var props: [String] = []
        if let id = id { props.append("id: \(id)") }
        if let styleId = styleId { props.append("style: \(styleId)") }
        if let dataSourceId = dataSourceId { props.append("data: \(dataSourceId)") }
        if let label = label { props.append("label: \"\(label)\"") }
        if !props.isEmpty {
            desc += " (\(props.joined(separator: ", ")))"
        }

        return prefix + desc
    }
}

// MARK: - StateValue Debug

extension StateValue {
    var debugValue: String {
        switch self {
        case .intValue(let v): return "\(v)"
        case .doubleValue(let v): return "\(v)"
        case .stringValue(let v): return "\"\(v)\""
        case .boolValue(let v): return "\(v)"
        case .nullValue: return "null"
        }
    }
}

// MARK: - DataSource Debug

extension DataSource {
    var debugValue: String {
        switch type {
        case .static:
            if let value = value {
                return "static(\"\(value)\")"
            }
            return "static(nil)"
        case .binding:
            return "binding(\(path ?? "?"))"
        }
    }
}
