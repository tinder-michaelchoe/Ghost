//
//  ContentView.swift
//  StaticExamples
//
//  Created by mexicanpizza on 12/23/25.
//

import CLADS
import CladsModules
import CoreContracts
import SwiftUI

struct CladsExamplesView: View {
    let weatherService: WeatherService

    @State private var selectedExample: Example?
    @State private var fullScreenExample: Example?
    @State private var jsonViewerExample: Example?

    var body: some View {
        NavigationStack {
            List {
                // CLADS Categories
                Section("C - Components") {
                    ForEach(Example.componentExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("L - Layouts") {
                    ForEach(Example.layoutExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("A - Actions") {
                    ForEach(Example.actionExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("D - Data") {
                    ForEach(Example.dataExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("S - Styles") {
                    ForEach(Example.styleExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }

                Section("Complex Examples") {
                    ForEach(Example.complexExamples) { example in
                        ExampleRow(
                            example: example,
                            selectedExample: $selectedExample,
                            fullScreenExample: $fullScreenExample,
                            jsonViewerExample: $jsonViewerExample
                        )
                    }
                }
            }
            .navigationTitle("CLADS Examples")
            .sheet(item: $selectedExample) { example in
                Group {
                    switch example {
                    case .dadJokes:
                        DadJokesExampleView()
                    case .taskManager:
                        TaskManagerExampleView()
                    case .weatherDashboard:
                        WeatherDashboardExampleView(weatherService: weatherService)
                    case .deeplinks:
                        DeeplinkExampleView()
                    default:
                        ExampleSheetView(example: example)
                    }
                }
                .modifier(PresentationStyleModifier(style: example.presentation))
            }
            .fullScreenCover(item: $fullScreenExample) { example in
                switch example {
                case .dadJokes:
                    DadJokesExampleView()
                case .taskManager:
                    TaskManagerExampleView()
                default:
                    ExampleSheetView(example: example)
                }
            }
            .sheet(item: $jsonViewerExample) { example in
                JSONViewerSheet(example: example)
            }
        }
    }
}

// MARK: - JSON Viewer Sheet

struct JSONViewerSheet: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let json = example.json {
                    Text(formatJSON(json))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text("No JSON available for this example")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .navigationTitle(example.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if example.json != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let json = example.json {
                                UIPasteboard.general.string = json
                            }
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func formatJSON(_ json: String) -> String {
        // Try to pretty-print the JSON
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return json
        }
        return prettyString
    }
}

struct ExampleRow: View {
    let example: Example
    @Binding var selectedExample: Example?
    @Binding var fullScreenExample: Example?
    @Binding var jsonViewerExample: Example?

    var body: some View {
        Button {
            if case .fullScreen = example.presentation {
                fullScreenExample = example
            } else {
                selectedExample = example
            }
        } label: {
            HStack {
                Image(systemName: example.icon)
                    .foregroundStyle(example.iconColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(example.title)
                        .foregroundColor(Color(uiColor: .label))
                    if let subtitle = example.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .contextMenu {
            if example.json != nil {
                Button {
                    jsonViewerExample = example
                } label: {
                    Label("View JSON", systemImage: "curlybraces")
                }

                Button {
                    if let json = example.json {
                        UIPasteboard.general.string = json
                    }
                } label: {
                    Label("Copy JSON", systemImage: "doc.on.doc")
                }
            }
        }
    }
}

// MARK: - Presentation Style

enum PresentationStyle: Equatable {
    /// Standard detent (.medium, .large, or custom fraction/height)
    case detent(PresentationDetent)
    /// Fixed height in points
    case fixed(height: CGFloat)
    /// Automatically sizes to fit content
    case autoSize
    /// Full sheet size (large detent)
    case fullSize
    /// Full screen cover (no sheet chrome)
    case fullScreen

    var label: String {
        switch self {
        case .detent(let detent):
            if detent == .medium { return "Detent: Medium" }
            if detent == .large { return "Detent: Large" }
            return "Detent"
        case .fixed(let height): return "\(Int(height))pt"
        case .autoSize: return "Auto"
        case .fullSize: return "Full"
        case .fullScreen: return "Screen"
        }
    }
}

// MARK: - Example Enum

enum Example: String, CaseIterable, Identifiable {
    // Components (C)
    case labels
    case buttons
    case textFields
    case toggles
    case sliders
    case images
    case gradients

    // Layouts (L)
    case vstackHstack
    case zstack
    case sectionLayoutList
    case sectionLayoutGrid
    case sectionLayoutFlow
    case sectionLayoutHorizontal

    // Actions (A)
    case setState
    case toggleState
    case showAlert
    case dismiss
    case navigate
    case sequence
    case arrayActions

    // Data (D)
    case staticData
    case bindingData
    case expressionData
    case stateInterpolation

    // Styles (S)
    case basicStyles
    case styleInheritance
    case conditionalStyles

    // Complex Examples (Combining CLADS Elements)
    case dadJokes
    case taskManager
    case shoppingCart
    case musicPlayer
    case weatherDashboard
    case deeplinks

    var id: String { rawValue }

    var title: String {
        switch self {
        // Components
        case .labels: return "Labels"
        case .buttons: return "Buttons"
        case .textFields: return "Text Fields"
        case .toggles: return "Toggles"
        case .sliders: return "Sliders"
        case .images: return "Images"
        case .gradients: return "Gradients"
        // Layouts
        case .vstackHstack: return "VStack & HStack"
        case .zstack: return "ZStack"
        case .sectionLayoutList: return "Section: List"
        case .sectionLayoutGrid: return "Section: Grid"
        case .sectionLayoutFlow: return "Section: Flow"
        case .sectionLayoutHorizontal: return "Section: Horizontal"
                // Actions
        case .setState: return "Set State"
        case .toggleState: return "Toggle State"
        case .showAlert: return "Show Alert"
        case .dismiss: return "Dismiss"
        case .navigate: return "Navigate"
        case .sequence: return "Sequence Actions"
        case .arrayActions: return "Array Actions"
        // Data
        case .staticData: return "Static Data"
        case .bindingData: return "Binding Data"
        case .expressionData: return "Expressions"
        case .stateInterpolation: return "State Interpolation"
        // Styles
        case .basicStyles: return "Basic Styles"
        case .styleInheritance: return "Style Inheritance"
        case .conditionalStyles: return "Conditional Styles"
        // Complex
        case .dadJokes: return "Dad Jokes"
        case .taskManager: return "Task Manager"
        case .shoppingCart: return "Shopping Cart"
        case .musicPlayer: return "Music Player"
        case .weatherDashboard: return "Weather Dashboard"
        case .deeplinks: return "Deeplinks"
        }
    }

    var subtitle: String? {
        switch self {
        // Components
        case .labels: return "Text display with styles"
        case .buttons: return "Tappable actions"
        case .textFields: return "User input"
        case .toggles: return "Boolean switches"
        case .sliders: return "Range selection"
        case .images: return "System & URL images"
        case .gradients: return "Color transitions"
        // Layouts
        case .vstackHstack: return "Vertical & horizontal stacks"
        case .zstack: return "Layered overlays"
        case .sectionLayoutList: return "Vertical list with dividers"
        case .sectionLayoutGrid: return "Multi-column grid"
        case .sectionLayoutFlow: return "Wrapping flow layout"
        case .sectionLayoutHorizontal: return "Scrolling carousel"
                // Actions
        case .setState: return "Update state values"
        case .toggleState: return "Toggle boolean state"
        case .showAlert: return "Display alert dialogs"
        case .dismiss: return "Close the view"
        case .navigate: return "Push new screens"
        case .sequence: return "Chain multiple actions"
        case .arrayActions: return "Add/remove array items"
        // Data
        case .staticData: return "Fixed values"
        case .bindingData: return "Two-way state binding"
        case .expressionData: return "Computed values"
        case .stateInterpolation: return "Template strings"
        // Styles
        case .basicStyles: return "Font, color, spacing"
        case .styleInheritance: return "Extending base styles"
        case .conditionalStyles: return "State-based styling"
        // Complex
        case .dadJokes: return "Custom actions with REST API"
        case .taskManager: return "Dynamic task list with state"
        case .shoppingCart: return "E-commerce cart with promo codes"
        case .musicPlayer: return "Player controls, queue & progress"
        case .weatherDashboard: return "Forecast with gradient backgrounds"
        case .deeplinks: return "Tab navigation & sheet presentation"
        }
    }

    var icon: String {
        switch self {
        // Components
        case .labels: return "textformat"
        case .buttons: return "hand.tap"
        case .textFields: return "character.cursor.ibeam"
        case .toggles: return "switch.2"
        case .sliders: return "slider.horizontal.3"
        case .images: return "photo"
        case .gradients: return "paintbrush"
        // Layouts
        case .vstackHstack: return "square.split.2x1"
        case .zstack: return "square.stack"
        case .sectionLayoutList: return "list.bullet"
        case .sectionLayoutGrid: return "square.grid.2x2"
        case .sectionLayoutFlow: return "rectangle.3.group"
        case .sectionLayoutHorizontal: return "scroll"
                // Actions
        case .setState: return "arrow.right.circle"
        case .toggleState: return "arrow.triangle.swap"
        case .showAlert: return "exclamationmark.bubble"
        case .dismiss: return "xmark.circle"
        case .navigate: return "arrow.right.square"
        case .sequence: return "list.number"
        case .arrayActions: return "plus.slash.minus"
        // Data
        case .staticData: return "doc.text"
        case .bindingData: return "link"
        case .expressionData: return "function"
        case .stateInterpolation: return "textformat.abc.dottedunderline"
        // Styles
        case .basicStyles: return "paintpalette"
        case .styleInheritance: return "arrow.up.right.circle"
        case .conditionalStyles: return "questionmark.diamond"
        // Complex
        case .dadJokes: return "face.smiling"
        case .taskManager: return "checklist"
        case .shoppingCart: return "cart.fill"
        case .musicPlayer: return "music.note.list"
        case .weatherDashboard: return "cloud.sun.fill"
        case .deeplinks: return "link"
        }
    }

    var iconColor: Color {
        switch self {
        // Components - Blue shades
        case .labels: return .blue
        case .buttons: return .blue
        case .textFields: return .blue
        case .toggles: return .blue
        case .sliders: return .blue
        case .images: return .blue
        case .gradients: return .blue
        // Layouts - Purple shades
        case .vstackHstack: return .purple
        case .zstack: return .purple
        case .sectionLayoutList: return .purple
        case .sectionLayoutGrid: return .purple
        case .sectionLayoutFlow: return .purple
        case .sectionLayoutHorizontal: return .purple
                // Actions - Orange shades
        case .setState: return .orange
        case .toggleState: return .orange
        case .showAlert: return .orange
        case .dismiss: return .orange
        case .navigate: return .orange
        case .sequence: return .orange
        case .arrayActions: return .orange
        // Data - Green shades
        case .staticData: return .green
        case .bindingData: return .green
        case .expressionData: return .green
        case .stateInterpolation: return .green
        // Styles - Pink shades
        case .basicStyles: return .pink
        case .styleInheritance: return .pink
        case .conditionalStyles: return .pink
        // Complex - Teal/Indigo
        case .dadJokes: return .yellow
        case .taskManager: return .indigo
        case .shoppingCart: return .teal
        case .musicPlayer: return .teal
        case .weatherDashboard: return .indigo
        case .deeplinks: return .blue
        }
    }

    var json: String? {
        switch self {
        // Components
        case .labels: return labelsJSON
        case .buttons: return buttonsJSON
        case .textFields: return textFieldsJSON
        case .toggles: return togglesJSON
        case .sliders: return slidersJSON
        case .images: return imagesJSON
        case .gradients: return gradientsJSON
        // Layouts
        case .vstackHstack: return vstackHstackJSON
        case .zstack: return zstackJSON
        case .sectionLayoutList: return sectionListJSON
        case .sectionLayoutGrid: return sectionGridJSON
        case .sectionLayoutFlow: return sectionFlowJSON
        case .sectionLayoutHorizontal: return sectionHorizontalJSON
                // Actions
        case .setState: return setStateJSON
        case .toggleState: return toggleStateJSON
        case .showAlert: return showAlertJSON
        case .dismiss: return dismissJSON
        case .navigate: return navigateJSON
        case .sequence: return sequenceJSON
        case .arrayActions: return arrayActionsJSON
        // Data
        case .staticData: return staticDataJSON
        case .bindingData: return bindingDataJSON
        case .expressionData: return expressionDataJSON
        case .stateInterpolation: return stateInterpolationJSON
        // Styles
        case .basicStyles: return basicStylesJSON
        case .styleInheritance: return styleInheritanceJSON
        case .conditionalStyles: return conditionalStylesJSON
        // Complex
        case .dadJokes: return dadJokesJSON
        case .taskManager: return taskManagerJSON
        case .shoppingCart: return shoppingCartJSON
        case .musicPlayer: return musicPlayerJSON
        case .weatherDashboard: return weatherDashboardJSON
        case .deeplinks: return deeplinkExampleJSON
        }
    }

    var presentation: PresentationStyle {
        switch self {
        // Most basic examples work well with medium detent
        case .labels, .buttons, .textFields, .toggles, .sliders, .images, .gradients:
            return .detent(.medium)
        case .vstackHstack, .zstack:
            return .detent(.medium)
        case .sectionLayoutList, .sectionLayoutGrid, .sectionLayoutFlow, .sectionLayoutHorizontal:
            return .fullSize
        case .setState, .toggleState, .showAlert, .dismiss, .navigate, .sequence, .arrayActions:
            return .detent(.medium)
        case .staticData, .bindingData, .expressionData, .stateInterpolation:
            return .detent(.medium)
        case .basicStyles, .styleInheritance, .conditionalStyles:
            return .detent(.medium)
        // Complex examples - full size sheets
        case .dadJokes: return .detent(.medium)
        case .taskManager: return .fullSize
        case .shoppingCart: return .fullSize
        case .musicPlayer: return .fullSize
        case .weatherDashboard: return .fullSize
        case .deeplinks: return .fullSize
        }
    }

    // MARK: - Category Arrays

    static var componentExamples: [Example] {
        [.labels, .buttons, .textFields, .toggles, .sliders, .images, .gradients]
    }

    static var layoutExamples: [Example] {
        [.vstackHstack, .zstack, .sectionLayoutList, .sectionLayoutGrid, .sectionLayoutFlow, .sectionLayoutHorizontal]
    }

    static var actionExamples: [Example] {
        [.setState, .toggleState, .showAlert, .dismiss, .navigate, .sequence, .arrayActions]
    }

    static var dataExamples: [Example] {
        [.staticData, .bindingData, .expressionData, .stateInterpolation]
    }

    static var styleExamples: [Example] {
        [.basicStyles, .styleInheritance, .conditionalStyles]
    }

    static var complexExamples: [Example] {
        [.dadJokes, .taskManager, .shoppingCart, .musicPlayer, .weatherDashboard, .deeplinks]
    }
}

// MARK: - Example Sheet View

struct ExampleSheetView: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let json = example.json,
               let view = CladsRendererView(jsonString: json, debugMode: true) {
                view
            } else {
                errorView
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Failed to parse JSON")
                .foregroundStyle(.secondary)
            Button("Dismiss") {
                dismiss()
            }
        }
    }
}

// MARK: - Presentation Style Modifier

struct PresentationStyleModifier: ViewModifier {
    let style: PresentationStyle

    func body(content: Content) -> some View {
        switch style {
        case .detent(let detent):
            content
                .presentationDetents([detent])
                .presentationDragIndicator(.visible)

        case .fixed(let height):
            content
                .presentationDetents([.height(height)])
                .presentationDragIndicator(.visible)

        case .autoSize:
            content
                .presentationSizing(.fitted)
                .presentationDragIndicator(.visible)

        case .fullSize:
            content
                .presentationSizing(.page)
                .presentationDragIndicator(.visible)

        case .fullScreen:
            content
        }
    }
}
