//
//  DebugRenderer.swift
//  CladsRendererFramework
//
//  Renders a RenderTree into a debug string for console output.
//

import Foundation
import SwiftUI

// MARK: - Debug Renderer

/// Renders a RenderTree into a debug string
public struct DebugRenderer: Renderer {

    public init() {}

    public func render(_ tree: RenderTree) -> String {
        var lines: [String] = []

        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        lines.append("RenderTree")
        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Root
        lines.append("")
        lines.append("Root:")
        lines.append(renderRoot(tree.root, indent: 1))

        // Actions
        if !tree.actions.isEmpty {
            lines.append("")
            lines.append("Actions:")
            for (id, action) in tree.actions.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(id): \(actionDescription(action))")
            }
        }

        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        return lines.joined(separator: "\n")
    }

    // MARK: - Root Rendering

    private func renderRoot(_ root: RootNode, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var props: [String] = []
        if let bg = root.backgroundColor {
            props.append("bg: \(bg.description)")
        }
        if root.edgeInsets != nil {
            props.append("edgeInsets")
        }

        let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
        lines.append("\(prefix)root\(propsStr)")

        for child in root.children {
            lines.append(renderNode(child, indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Node Rendering

    private func renderNode(_ node: RenderNode, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)

        switch node {
        case .container(let container):
            return renderContainer(container, indent: indent)

        case .sectionLayout(let sectionLayout):
            return renderSectionLayout(sectionLayout, indent: indent)

        case .text(let text):
            var props: [String] = []
            if let id = text.id { props.append("id: \(id)") }
            props.append("content: \"\(text.content)\"")
            let propsStr = props.joined(separator: ", ")
            return "\(prefix)text (\(propsStr))"

        case .button(let button):
            var props: [String] = []
            if let id = button.id { props.append("id: \(id)") }
            props.append("label: \"\(button.label)\"")
            if button.fillWidth { props.append("fillWidth") }
            if let onTap = button.onTap { props.append("onTap: \(onTap)") }
            let propsStr = props.joined(separator: ", ")
            return "\(prefix)button (\(propsStr))"

        case .textField(let textField):
            var props: [String] = []
            if let id = textField.id { props.append("id: \(id)") }
            if !textField.placeholder.isEmpty { props.append("placeholder: \"\(textField.placeholder)\"") }
            if let path = textField.bindingPath { props.append("binding: \(path)") }
            let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
            return "\(prefix)textField\(propsStr)"

        case .image(let image):
            var props: [String] = []
            if let id = image.id { props.append("id: \(id)") }
            props.append("source: \(imageSourceDescription(image.source))")
            let propsStr = props.joined(separator: ", ")
            return "\(prefix)image (\(propsStr))"

        case .toggle(let toggle):
            var props: [String] = []
            if let id = toggle.id { props.append("id: \(id)") }
            if let path = toggle.bindingPath { props.append("binding: \(path)") }
            let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
            return "\(prefix)toggle\(propsStr)"

        case .slider(let slider):
            var props: [String] = []
            if let id = slider.id { props.append("id: \(id)") }
            if let path = slider.bindingPath { props.append("binding: \(path)") }
            props.append("range: \(slider.minValue)...\(slider.maxValue)")
            let propsStr = props.joined(separator: ", ")
            return "\(prefix)slider (\(propsStr))"

        case .gradient(let gradient):
            var props: [String] = []
            if let id = gradient.id { props.append("id: \(id)") }
            props.append("colors: \(gradient.colors.count)")
            props.append("from: \(gradient.startPoint)")
            props.append("to: \(gradient.endPoint)")
            let propsStr = props.joined(separator: ", ")
            return "\(prefix)gradient (\(propsStr))"

        case .spacer:
            return "\(prefix)spacer"

        case .divider(let divider):
            var props: [String] = []
            if let id = divider.id { props.append("id: \(id)") }
            let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
            return "\(prefix)divider\(propsStr)"

        case .custom(let kind, _):
            return "\(prefix)custom (kind: \(kind.rawValue))"
        }
    }

    private func renderSectionLayout(_ sectionLayout: SectionLayoutNode, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var props: [String] = []
        if let id = sectionLayout.id { props.append("id: \(id)") }
        props.append("sections: \(sectionLayout.sections.count)")
        if sectionLayout.sectionSpacing > 0 { props.append("spacing: \(Int(sectionLayout.sectionSpacing))") }

        let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
        lines.append("\(prefix)sectionLayout\(propsStr)")

        for section in sectionLayout.sections {
            lines.append(renderSection(section, indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }

    private func renderSection(_ section: IR.Section, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        var props: [String] = []
        if let id = section.id { props.append("id: \(id)") }
        props.append("layout: \(sectionTypeDescription(section.layoutType))")
        props.append("children: \(section.children.count)")
        if section.stickyHeader { props.append("stickyHeader") }

        let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
        lines.append("\(prefix)section\(propsStr)")

        if let header = section.header {
            lines.append("\(prefix)  header:")
            lines.append(renderNode(header, indent: indent + 2))
        }

        for child in section.children {
            lines.append(renderNode(child, indent: indent + 2))
        }

        if let footer = section.footer {
            lines.append("\(prefix)  footer:")
            lines.append(renderNode(footer, indent: indent + 2))
        }

        return lines.joined(separator: "\n")
    }

    private func sectionTypeDescription(_ type: IR.SectionType) -> String {
        switch type {
        case .horizontal: return "horizontal"
        case .list: return "list"
        case .grid(let columns):
            switch columns {
            case .fixed(let count): return "grid(fixed: \(count))"
            case .adaptive(let minWidth): return "grid(adaptive: \(Int(minWidth)))"
            }
        case .flow: return "flow"
        }
    }

    private func renderContainer(_ container: ContainerNode, indent: Int) -> String {
        let prefix = String(repeating: "  ", count: indent)
        var lines: [String] = []

        let layoutName: String
        switch container.layoutType {
        case .vstack: layoutName = "vstack"
        case .hstack: layoutName = "hstack"
        case .zstack: layoutName = "zstack"
        }

        var props: [String] = []
        if let id = container.id { props.append("id: \(id)") }
        if container.spacing > 0 { props.append("spacing: \(Int(container.spacing))") }
        props.append("align: \(alignmentDescription(container.alignment))")

        let propsStr = props.isEmpty ? "" : " (\(props.joined(separator: ", ")))"
        lines.append("\(prefix)\(layoutName)\(propsStr)")

        for child in container.children {
            lines.append(renderNode(child, indent: indent + 1))
        }

        return lines.joined(separator: "\n")
    }

    private func alignmentDescription(_ alignment: SwiftUI.Alignment) -> String {
        if alignment == .center { return "center" }
        if alignment == .leading { return "leading" }
        if alignment == .trailing { return "trailing" }
        if alignment == .top { return "top" }
        if alignment == .bottom { return "bottom" }
        if alignment == .topLeading { return "topLeading" }
        if alignment == .topTrailing { return "topTrailing" }
        if alignment == .bottomLeading { return "bottomLeading" }
        if alignment == .bottomTrailing { return "bottomTrailing" }
        return "custom"
    }

    // MARK: - Helpers

    private func imageSourceDescription(_ source: ImageNode.Source) -> String {
        switch source {
        case .system(let name): return "system(\(name))"
        case .asset(let name): return "asset(\(name))"
        case .url(let url): return "url(\(url.absoluteString))"
        }
    }

    private func actionDescription(_ action: ActionDefinition) -> String {
        switch action {
        case .dismiss:
            return "dismiss"
        case .setState(let path, let value):
            return "setState(\(path), \(stateValueDescription(value)))"
        case .toggleState(let path):
            return "toggleState(\(path))"
        case .showAlert(let config):
            return "showAlert(\"\(config.title)\")"
        case .sequence(let steps):
            return "sequence[\(steps.count) steps]"
        case .navigate(let dest, let pres):
            return "navigate(\(dest), \(pres.rawValue))"
        case .custom(let type, _):
            return "custom(\(type))"
        }
    }

    private func stateValueDescription(_ value: StateSetValue) -> String {
        switch value {
        case .literal(let v): return "\(v)"
        case .expression(let expr): return "expr(\(expr))"
        }
    }
}
