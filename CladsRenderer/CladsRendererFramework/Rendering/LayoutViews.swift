//
//  LayoutViews.swift
//  CladsRendererFramework
//

import SwiftUI

// MARK: - Layout Builder

struct LayoutView: View {
    let layout: Document.Layout
    let styleResolver: StyleResolver
    let dataSources: [String: Document.DataSource]?
    @EnvironmentObject var stateStore: StateStore
    @EnvironmentObject var context: ActionContext

    var body: some View {
        switch layout.type {
        case .vstack:
            buildVStack()
        case .hstack:
            buildHStack()
        case .zstack:
            buildZStack()
        }
    }

    @ViewBuilder
    private func buildVStack() -> some View {
        let alignment = layout.horizontalAlignment?.toSwiftUIHorizontal() ?? .center

        VStack(alignment: alignment, spacing: layout.spacing ?? 8) {
            ForEach(Array(layout.children.enumerated()), id: \.offset) { _, child in
                buildChild(child)
            }
        }
        .applyPadding(layout.padding)
    }

    @ViewBuilder
    private func buildHStack() -> some View {
        let alignment = layout.alignment?.vertical?.toSwiftUIVertical() ?? .center

        HStack(alignment: alignment, spacing: layout.spacing ?? 8) {
            ForEach(Array(layout.children.enumerated()), id: \.offset) { _, child in
                buildChild(child)
            }
        }
        .applyPadding(layout.padding)
    }

    @ViewBuilder
    private func buildZStack() -> some View {
        let alignment = buildAlignment(layout.alignment)

        ZStack(alignment: alignment) {
            ForEach(Array(layout.children.enumerated()), id: \.offset) { _, child in
                buildChild(child)
            }
        }
        .applyPadding(layout.padding)
    }

    private func buildAlignment(_ alignment: Document.Alignment?) -> SwiftUI.Alignment {
        let h = alignment?.horizontal ?? .center
        let v = alignment?.vertical ?? .center

        switch (h, v) {
        case (.leading, .top): return .topLeading
        case (.center, .top): return .top
        case (.trailing, .top): return .topTrailing
        case (.leading, .center): return .leading
        case (.center, .center): return .center
        case (.trailing, .center): return .trailing
        case (.leading, .bottom): return .bottomLeading
        case (.center, .bottom): return .bottom
        case (.trailing, .bottom): return .bottomTrailing
        }
    }

    @ViewBuilder
    private func buildChild(_ node: Document.LayoutNode) -> some View {
        switch node {
        case .layout(let childLayout):
            LayoutView(
                layout: childLayout,
                styleResolver: styleResolver,
                dataSources: dataSources
            )

        case .sectionLayout:
            // SectionLayout is handled by the resolved IR pipeline (SwiftUIRenderer)
            EmptyView()

        case .component(let component):
            ComponentView(
                component: component,
                styleResolver: styleResolver,
                dataSources: dataSources
            )

        case .spacer:
            Spacer()
        }
    }
}

// MARK: - Component Builder

struct ComponentView: View {
    let component: Document.Component
    let styleResolver: StyleResolver
    let dataSources: [String: Document.DataSource]?
    @EnvironmentObject var stateStore: StateStore
    @EnvironmentObject var context: ActionContext

    var body: some View {
        let style = styleResolver.resolve(component.styleId)

        switch component.type {
        case .label:
            LabelView(
                component: component,
                style: style,
                text: resolveText()
            )

        case .button:
            ButtonView(component: component, style: style)

        case .textfield:
            TextFieldView(component: component, style: style)

        case .image:
            // Placeholder for image component
            EmptyView()

        case .gradient:
            // Gradient is handled by the new pipeline (SwiftUIRenderer)
            EmptyView()
        }
    }

    private func resolveText() -> String {
        // Priority: data reference > dataSourceId > inline label
        if let dataRef = component.data {
            return resolveDataReference(dataRef)
        }

        if let dataSourceId = component.dataSourceId,
           let dataSource = dataSources?[dataSourceId] {
            return resolveDataSource(dataSource)
        }

        return component.text ?? ""
    }

    private func resolveDataReference(_ ref: Document.DataReference) -> String {
        switch ref.type {
        case .static:
            return ref.value ?? ""
        case .binding:
            if let path = ref.path {
                return stateStore.get(path) as? String ?? ""
            }
            if let template = ref.template {
                return stateStore.interpolate(template)
            }
            return ""
        case .localBinding:
            // Local binding is handled at resolution time, not here
            // Return empty for now - local state requires ViewNode context
            return ref.path.map { "[\($0)]" } ?? ""
        }
    }

    private func resolveDataSource(_ dataSource: Document.DataSource) -> String {
        switch dataSource.type {
        case .static:
            return dataSource.value ?? ""
        case .binding:
            if let path = dataSource.path {
                return stateStore.get(path) as? String ?? ""
            }
            return ""
        }
    }
}

// MARK: - Padding Extension

extension View {
    func applyPadding(_ padding: Document.Padding?) -> some View {
        guard let padding = padding else { return AnyView(self) }

        return AnyView(
            self
                .padding(.top, padding.resolvedTop)
                .padding(.bottom, padding.resolvedBottom)
                .padding(.leading, padding.resolvedLeading)
                .padding(.trailing, padding.resolvedTrailing)
        )
    }
}

// MARK: - Alignment Conversions

extension Document.HorizontalAlignment {
    func toSwiftUIHorizontal() -> SwiftUI.HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

extension Document.VerticalAlignment {
    func toSwiftUIVertical() -> SwiftUI.VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}
