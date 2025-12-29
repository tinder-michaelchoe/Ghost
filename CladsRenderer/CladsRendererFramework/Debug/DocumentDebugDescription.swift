//
//  DocumentDebugDescription.swift
//  CladsRendererFramework
//

import Foundation

// MARK: - Document Debug Description

extension Document.Definition: CustomDebugStringConvertible {
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
                lines.append("  \(key): \(action.debugTypeName)")
            }
        }

        // Root Component Tree
        lines.append("")
        lines.append("Component Tree:")
        lines.append(root.debugDescription(indent: 1))

        return lines.joined(separator: "\n")
    }

    /// Build a tree representation of style inheritance
    private func buildStyleTree(_ styles: [String: Document.Style]) -> [String] {
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

extension Document.RootComponent {
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

extension Document.LayoutNode {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        switch self {
        case .layout(let layout):
            return layout.debugDescription(indent: indent)
        case .sectionLayout(let sectionLayout):
            return sectionLayout.debugDescription(indent: indent)
        case .component(let component):
            return component.debugDescription(indent: indent)
        case .spacer:
            return prefix + "spacer"
        }
    }
}

// MARK: - Layout Debug

extension Document.Layout {
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

// MARK: - SectionLayout Debug

extension Document.SectionLayout {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var desc = "sectionLayout"
        var props: [String] = []
        if let id = id { props.append("id: \(id)") }
        if let spacing = sectionSpacing { props.append("spacing: \(Int(spacing))") }
        props.append("sections: \(sections.count)")
        if !props.isEmpty {
            desc += " (\(props.joined(separator: ", ")))"
        }
        lines.append(prefix + desc)

        for section in sections {
            lines.append(section.debugDescription(indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }
}

extension Document.SectionDefinition {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var desc = "section"
        var props: [String] = []
        if let id = id { props.append("id: \(id)") }
        props.append("layout: \(layout.type.rawValue)")
        if let staticChildren = children { props.append("children: \(staticChildren.count)") }
        if let ds = dataSource { props.append("dataSource: \(ds)") }
        if stickyHeader == true { props.append("stickyHeader") }
        if !props.isEmpty {
            desc += " (\(props.joined(separator: ", ")))"
        }
        lines.append(prefix + desc)

        if let header = header {
            lines.append(prefix + "  header:")
            lines.append(header.debugDescription(indent: indent + 2))
        }

        if let staticChildren = children {
            for child in staticChildren {
                lines.append(child.debugDescription(indent: indent + 1))
            }
        }

        if let template = itemTemplate {
            lines.append(prefix + "  itemTemplate:")
            lines.append(template.debugDescription(indent: indent + 2))
        }

        if let footer = footer {
            lines.append(prefix + "  footer:")
            lines.append(footer.debugDescription(indent: indent + 2))
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Component Debug

extension Document.Component {
    func debugDescription(indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        var desc = type.rawValue
        var props: [String] = []
        if let id = id { props.append("id: \(id)") }
        if let styleId = styleId { props.append("style: \(styleId)") }
        if let dataSourceId = dataSourceId { props.append("data: \(dataSourceId)") }
        if let text = text { props.append("text: \"\(text)\"") }
        if !props.isEmpty {
            desc += " (\(props.joined(separator: ", ")))"
        }

        return prefix + desc
    }
}

// MARK: - StateValue Debug

extension Document.StateValue {
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

extension Document.DataSource {
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

// MARK: - Action Debug

extension Document.Action {
    var debugTypeName: String {
        switch self {
        case .dismiss:
            return "dismiss"
        case .setState(let action):
            return "setState(path: \(action.path))"
        case .toggleState(let action):
            return "toggleState(path: \(action.path))"
        case .showAlert(let action):
            return "showAlert(title: \(action.title))"
        case .navigate(let action):
            return "navigate(destination: \(action.destination))"
        case .sequence(let action):
            return "sequence(steps: \(action.steps.count))"
        case .custom(let action):
            return "custom(\(action.type))"
        }
    }
}
