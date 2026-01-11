//
//  ContentView.swift
//  CladsRenderer
//

import CLADS
import CladsExamples
import CladsModules
import SwiftUI

struct ContentView: View {
    @State private var selectedExample: Example?
    @State private var fullScreenExample: Example?

    var body: some View {
        NavigationStack {
            List {
                Section("Basic Examples") {
                    ForEach(Example.basicExamples) { example in
                        ExampleRow(example: example, selectedExample: $selectedExample, fullScreenExample: $fullScreenExample)
                    }
                }

                Section("Advanced Examples") {
                    ForEach(Example.advancedExamples) { example in
                        ExampleRow(example: example, selectedExample: $selectedExample, fullScreenExample: $fullScreenExample)
                    }
                }
            }
            .navigationTitle("CladsRenderer")
            .sheet(item: $selectedExample) { example in
                Group {
                    switch example {
                    case .dadJokes:
                        DadJokesExampleView()
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
                default:
                    ExampleSheetView(example: example)
                }
            }
        }
    }
}

struct ExampleRow: View {
    let example: Example
    @Binding var selectedExample: Example?
    @Binding var fullScreenExample: Example?

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
    case componentShowcase
    case basic
    case sectionLayout
    case interests
    case dadJokes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .componentShowcase: return "Component Showcase"
        case .basic: return "Basic Example"
        case .sectionLayout: return "Section Layout"
        case .interests: return "Interests"
        case .dadJokes: return "Dad Jokes"
        }
    }

    var subtitle: String? {
        switch self {
        case .componentShowcase: return "All component types"
        case .basic: return "Welcome screen with actions"
        case .sectionLayout: return "Horizontal, grid, and list"
        case .interests: return "Flow layout with selectable pills"
        case .dadJokes: return "Custom actions with REST API"
        }
    }

    var icon: String {
        switch self {
        case .componentShowcase: return "square.stack.3d.up"
        case .basic: return "sparkles"
        case .sectionLayout: return "square.grid.2x2"
        case .interests: return "heart.circle"
        case .dadJokes: return "face.smiling"
        }
    }

    var iconColor: Color {
        switch self {
        case .componentShowcase: return .indigo
        case .basic: return .blue
        case .sectionLayout: return .purple
        case .interests: return .pink
        case .dadJokes: return .yellow
        }
    }

    var json: String? {
        switch self {
        case .componentShowcase: return componentShowcaseJSON
        case .basic: return basicExampleJSON
        case .sectionLayout: return sectionLayoutJSON
        case .interests: return interestsJSON
        case .dadJokes: return nil  // Custom view handles JSON
        }
    }

    var presentation: PresentationStyle {
        switch self {
        case .componentShowcase: return .fullScreen
        case .basic: return .autoSize
        case .sectionLayout: return .fullScreen
        case .interests: return .detent(.medium)
        case .dadJokes: return .detent(.medium)
        }
    }

    static var basicExamples: [Example] {
        [.componentShowcase, .basic, .sectionLayout, .interests]
    }

    static var advancedExamples: [Example] {
        [.dadJokes]
    }
}

// MARK: - Example Sheet View

public struct ExampleSheetView: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
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

#Preview {
    ContentView()
}
