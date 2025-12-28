//
//  ContentView.swift
//  CladsRenderer
//

import SwiftUI
import CladsRendererFramework

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
                switch example {
                case .tacoTruck:
                    TacoTruckExampleView()
                case .movieNight:
                    MovieNightExampleView()
                default:
                    ExampleSheetView(example: example)
                }
            }
            .fullScreenCover(item: $fullScreenExample) { example in
                switch example {
                case .tacoTruck:
                    TacoTruckExampleView()
                case .movieNight:
                    MovieNightExampleView()
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
                        .foregroundStyle(.primary)
                    if let subtitle = example.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
    case basic
    case favoritePlaces
    case sectionLayout
    case tacoTruck
    case movieNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: return "Basic Example"
        case .favoritePlaces: return "Favorite Places"
        case .sectionLayout: return "Section Layout"
        case .tacoTruck: return "Taco Truck"
        case .movieNight: return "Movie Night"
        }
    }

    var subtitle: String? {
        switch self {
        case .basic: return "Welcome screen with actions"
        case .favoritePlaces: return "Hero image with gradient"
        case .sectionLayout: return "Horizontal, grid, and list"
        case .tacoTruck: return "Typed state, callbacks, binding API"
        case .movieNight: return "UIKit renderer with delegate"
        }
    }

    var icon: String {
        switch self {
        case .basic: return "sparkles"
        case .favoritePlaces: return "mappin.and.ellipse"
        case .sectionLayout: return "square.grid.2x2"
        case .tacoTruck: return "fork.knife"
        case .movieNight: return "film"
        }
    }

    var iconColor: Color {
        switch self {
        case .basic: return .blue
        case .favoritePlaces: return .green
        case .sectionLayout: return .purple
        case .tacoTruck: return .orange
        case .movieNight: return .red
        }
    }

    var json: String {
        switch self {
        case .basic: return basicExampleJSON
        case .favoritePlaces: return favoritePlacesJSON
        case .sectionLayout: return sectionLayoutJSON
        case .tacoTruck: return tacoTruckJSON
        case .movieNight: return movieNightJSON
        }
    }

    var presentation: PresentationStyle {
        switch self {
        case .basic: return .autoSize
        case .favoritePlaces: return .detent(.medium)
        case .sectionLayout: return .fullScreen
        case .tacoTruck: return .fullSize
        case .movieNight: return .fullScreen
        }
    }

    static var basicExamples: [Example] {
        [.basic, .favoritePlaces, .sectionLayout]
    }

    static var advancedExamples: [Example] {
        [.tacoTruck, .movieNight]
    }
}

// MARK: - Example Sheet View

struct ExampleSheetView: View {
    let example: Example
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let view = CladsRendererView(jsonString: example.json, debugMode: true) {
                view
            } else {
                errorView
            }
        }
        .modifier(PresentationStyleModifier(style: example.presentation))
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

// MARK: - Example JSON

private let basicExampleJSON = """
{
  "id": "onboarding-prompt",
  "version": "1.0",

  "state": {
    "notYetCount": 0
  },

  "styles": {
    "baseText": {
      "fontFamily": "system",
      "textColor": "#000000"
    },
    "titleStyle": {
      "inherits": "baseText",
      "fontSize": 24,
      "fontWeight": "bold"
    },
    "subtitleStyle": {
      "inherits": "baseText",
      "fontSize": 16,
      "fontWeight": "regular",
      "textColor": "#666666"
    },
    "baseButton": {
      "cornerRadius": 12,
      "height": 50,
      "fontWeight": "semibold",
      "fontSize": 17
    },
    "primaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF"
    },
    "secondaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#E5E5EA",
      "textColor": "#000000"
    }
  },

  "dataSources": {
    "titleText": { "type": "static", "value": "Welcome to Clads" },
    "subtitleText": { "type": "static", "value": "Your server-driven UI framework" }
  },

  "actions": {
    "dismissView": {
      "type": "dismiss"
    },
    "showNotYetAlert": {
      "type": "sequence",
      "steps": [
        {
          "type": "setState",
          "path": "notYetCount",
          "value": { "$expr": "${notYetCount} + 1" }
        },
        {
          "type": "showAlert",
          "title": "Not ready?",
          "message": {
            "type": "binding",
            "template": "You've pressed this ${notYetCount} time(s)"
          },
          "buttons": [
            { "label": "OK", "style": "default" }
          ]
        }
      ]
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": {
      "bottom": { "mode": "safeArea", "padding": 20 }
    },
    "children": [
      {
        "type": "vstack",
        "alignment": "center",
        "spacing": 8,
        "children": [
          { "type": "spacer" },
          {
            "type": "label",
            "id": "titleLabel",
            "styleId": "titleStyle",
            "dataSourceId": "titleText"
          },
          {
            "type": "label",
            "id": "subtitleLabel",
            "styleId": "subtitleStyle",
            "dataSourceId": "subtitleText"
          },
          { "type": "spacer" },
          {
            "type": "vstack",
            "spacing": 12,
            "padding": { "horizontal": 20 },
            "children": [
              {
                "type": "button",
                "id": "gotItButton",
                "label": "Got it",
                "styleId": "primaryButton",
                "fillWidth": true,
                "actions": {
                  "onTap": "dismissView"
                }
              },
              {
                "type": "button",
                "id": "notYetButton",
                "label": "Not yet",
                "styleId": "secondaryButton",
                "fillWidth": true,
                "actions": {
                  "onTap": "showNotYetAlert"
                }
              }
            ]
          }
        ]
      }
    ]
  }
}
"""

private let favoritePlacesJSON = """
{
  "id": "favorite-places",
  "version": "1.0",

  "styles": {
    "headerStyle": {
      "fontSize": 28,
      "fontWeight": "bold",
      "textColor": "#FFFFFF"
    },
    "heroImage": {
      "height": 300
    },
    "heroGradient": {
      "height": 300
    }
  },

  "root": {
    "colorScheme": "system",
    "children": [
      {
        "type": "zstack",
        "alignment": { "horizontal": "leading", "vertical": "top" },
        "children": [
          {
            "type": "image",
            "id": "backgroundImage",
            "data": {
              "type": "static",
              "value": "url:https://images.pexels.com/photos/417074/pexels-photo-417074.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"
            },
            "styleId": "heroImage"
          },
          {
            "type": "gradient",
            "id": "overlayGradient",
            "gradientColors": [
              { "lightColor": "#FFFFFFFF", "darkColor": "#FF000000", "location": 0.0 },
              { "lightColor": "#00FFFFFF", "darkColor": "#00000000", "location": 0.4 }
            ],
            "gradientStart": "bottom",
            "gradientEnd": "top",
            "styleId": "heroGradient"
          },
          {
            "type": "vstack",
            "alignment": "leading",
            "padding": { "leading": 20, "top": 60 },
            "children": [
              {
                "type": "label",
                "id": "headerLabel",
                "label": "Favorite Places",
                "styleId": "headerStyle"
              }
            ]
          }
        ]
      },
      { "type": "spacer" }
    ]
  }
}
"""

private let sectionLayoutJSON = """
{
  "id": "section-layout-demo",
  "version": "1.0",

  "actions": {
    "dismissView": {
      "type": "dismiss"
    }
  },

  "styles": {
    "screenTitle": {
      "fontSize": 34,
      "fontWeight": "bold",
      "textColor": "#000000"
    },
    "sectionHeader": {
      "fontSize": 22,
      "fontWeight": "bold",
      "textColor": "#000000"
    },
    "closeButton": {
      "fontSize": 17,
      "fontWeight": "medium",
      "textColor": "#007AFF"
    },
    "cardTitle": {
      "fontSize": 16,
      "fontWeight": "semibold",
      "textColor": "#000000"
    },
    "cardSubtitle": {
      "fontSize": 14,
      "fontWeight": "regular",
      "textColor": "#666666"
    },
    "horizontalCard": {
      "width": 150,
      "height": 100,
      "backgroundColor": "#E8E8ED",
      "cornerRadius": 12
    },
    "gridCard": {
      "height": 120,
      "backgroundColor": "#E8E8ED",
      "cornerRadius": 12
    },
    "listItem": {
      "height": 60
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "colorScheme": "system",
    "children": [
      {
        "type": "hstack",
        "padding": { "horizontal": 16, "top": 16 },
        "children": [
          { "type": "spacer" },
          {
            "type": "button",
            "label": "Close",
            "styleId": "closeButton",
            "actions": { "onTap": "dismissView" }
          }
        ]
      },
      {
        "type": "hstack",
        "padding": { "horizontal": 16, "bottom": 8 },
        "children": [
          { "type": "label", "label": "Section Layouts", "styleId": "screenTitle" }
        ]
      },
      {
        "type": "sectionLayout",
        "id": "main-sections",
        "sectionSpacing": 24,
        "sections": [
          {
            "id": "horizontal-section",
            "layout": "horizontal",
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "top": 8, "bottom": 8 },
              "children": [
                { "type": "label", "label": "Horizontal Scroll", "styleId": "sectionHeader" }
              ]
            },
            "config": {
              "itemSpacing": 12,
              "contentInsets": { "leading": 16, "trailing": 16 },
              "showsIndicators": false
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "label": "Item 1", "styleId": "cardTitle" },
                  { "type": "label", "label": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "label": "Item 2", "styleId": "cardTitle" },
                  { "type": "label", "label": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "label": "Item 3", "styleId": "cardTitle" },
                  { "type": "label", "label": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "label": "Item 4", "styleId": "cardTitle" },
                  { "type": "label", "label": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "label": "Item 5", "styleId": "cardTitle" },
                  { "type": "label", "label": "Description", "styleId": "cardSubtitle" }
                ]
              }
            ]
          },
          {
            "id": "grid-section",
            "layout": "grid",
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "bottom": 8 },
              "children": [
                { "type": "label", "label": "Grid Layout", "styleId": "sectionHeader" }
              ]
            },
            "config": {
              "columns": 2,
              "itemSpacing": 12,
              "lineSpacing": 12,
              "contentInsets": { "horizontal": 16 }
            },
            "children": [
              { "type": "label", "label": "Grid Item 1", "styleId": "cardTitle" },
              { "type": "label", "label": "Grid Item 2", "styleId": "cardTitle" },
              { "type": "label", "label": "Grid Item 3", "styleId": "cardTitle" },
              { "type": "label", "label": "Grid Item 4", "styleId": "cardTitle" }
            ]
          },
          {
            "id": "list-section",
            "layout": "list",
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "bottom": 8 },
              "children": [
                { "type": "label", "label": "List Layout", "styleId": "sectionHeader" }
              ]
            },
            "config": {
              "itemSpacing": 0,
              "showsDividers": true,
              "contentInsets": { "horizontal": 16 }
            },
            "children": [
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "label": "List Item 1", "styleId": "cardTitle" },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "label": "List Item 2", "styleId": "cardTitle" },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "label": "List Item 3", "styleId": "cardTitle" },
                  { "type": "spacer" }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
"""

// MARK: - Taco Truck Example (Binding API + Typed State + Callbacks)

/// Typed state model for the Taco Truck example
/// Demonstrates Codable bridging with CladsRendererBindingView
struct TacoOrderState: Codable, Equatable {
    var customerName: String = ""
    var tacoCount: Int = 1
    var burritoCount: Int = 0
    var selectedProtein: String = "Carnitas"
    var addGuac: Bool = false
    var addCheese: Bool = true
    var specialInstructions: String = ""
    var orderTotal: Double = 4.50

    var formattedTotal: String {
        String(format: "$%.2f", orderTotal)
    }
}

/// Example view demonstrating:
/// - CladsRendererBindingView with typed state
/// - Bidirectional state sync via Binding
/// - State change callbacks for analytics
/// - Real-time state display
struct TacoTruckExampleView: View {
    @Environment(\.dismiss) private var dismiss

    // Typed state that syncs with the CLADS view
    @State private var orderState = TacoOrderState()

    // Analytics/debug log
    @State private var stateChanges: [(path: String, value: String)] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // CLADS Rendered View
                cladsView
                    .frame(maxHeight: .infinity)

                Divider()

                // Debug panel showing state sync
                debugPanel
            }
            .navigationTitle("Taco Truck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        orderState = TacoOrderState()
                        stateChanges = []
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cladsView: some View {
        if let document = try? Document.Definition(jsonString: tacoTruckJSON) {
            let config = CladsRendererConfiguration<TacoOrderState>(
                initialState: orderState,
                onStateChange: { path, oldValue, newValue in
                    // This callback fires on every state mutation
                    let valueStr = newValue.map { String(describing: $0) } ?? "nil"
                    stateChanges.append((path: path, value: valueStr))

                    // Keep only last 10 changes
                    if stateChanges.count > 10 {
                        stateChanges.removeFirst()
                    }
                },
                onAction: { actionId, params in
                    print("Action executed: \(actionId)")
                },
                debugMode: false
            )

            CladsRendererBindingView(
                document: document,
                state: $orderState,
                configuration: config
            )
        } else {
            Text("Failed to parse JSON")
                .foregroundStyle(.red)
        }
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live State Sync")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current state display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StateBadge(label: "Customer", value: orderState.customerName.isEmpty ? "—" : orderState.customerName)
                    StateBadge(label: "Tacos", value: "\(orderState.tacoCount)")
                    StateBadge(label: "Burritos", value: "\(orderState.burritoCount)")
                    StateBadge(label: "Protein", value: orderState.selectedProtein)
                    StateBadge(label: "Total", value: orderState.formattedTotal)
                }
            }

            // Recent changes log
            if !stateChanges.isEmpty {
                Text("Recent Changes:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stateChanges.suffix(5).reversed(), id: \.path) { change in
                            Text("\(change.path): \(change.value)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}

struct StateBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private let tacoTruckJSON = """
{
  "id": "taco-truck-order",
  "version": "1.0",

  "state": {
    "customerName": "",
    "tacoCount": 1,
    "burritoCount": 0,
    "selectedProtein": "Carnitas",
    "addGuac": false,
    "addCheese": true,
    "specialInstructions": "",
    "orderTotal": 4.50
  },

  "styles": {
    "screenTitle": {
      "fontSize": 28,
      "fontWeight": "bold",
      "textColor": "#1a1a1a"
    },
    "sectionTitle": {
      "fontSize": 18,
      "fontWeight": "semibold",
      "textColor": "#333333"
    },
    "menuItemTitle": {
      "fontSize": 16,
      "fontWeight": "medium",
      "textColor": "#1a1a1a"
    },
    "menuItemPrice": {
      "fontSize": 14,
      "fontWeight": "regular",
      "textColor": "#666666"
    },
    "countDisplay": {
      "fontSize": 20,
      "fontWeight": "bold",
      "textColor": "#E85D04"
    },
    "proteinOption": {
      "fontSize": 15,
      "fontWeight": "medium",
      "textColor": "#333333"
    },
    "proteinSelected": {
      "fontSize": 15,
      "fontWeight": "bold",
      "textColor": "#FFFFFF",
      "backgroundColor": "#E85D04",
      "cornerRadius": 8
    },
    "totalLabel": {
      "fontSize": 18,
      "fontWeight": "semibold",
      "textColor": "#333333"
    },
    "totalAmount": {
      "fontSize": 24,
      "fontWeight": "bold",
      "textColor": "#E85D04"
    },
    "orderButton": {
      "fontSize": 18,
      "fontWeight": "bold",
      "backgroundColor": "#E85D04",
      "textColor": "#FFFFFF",
      "cornerRadius": 14,
      "height": 56
    },
    "countButton": {
      "fontSize": 20,
      "fontWeight": "bold",
      "backgroundColor": "#F0F0F0",
      "textColor": "#E85D04",
      "cornerRadius": 8,
      "width": 44,
      "height": 44
    },
    "inputField": {
      "fontSize": 16,
      "textColor": "#333333",
      "backgroundColor": "#F5F5F5",
      "cornerRadius": 10
    },
    "emoji": {
      "fontSize": 32
    }
  },

  "dataSources": {
    "welcomeText": {
      "type": "binding",
      "template": "Hey${customerName}, ready to order?"
    },
    "tacoCountDisplay": {
      "type": "binding",
      "path": "tacoCount"
    },
    "burritoCountDisplay": {
      "type": "binding",
      "path": "burritoCount"
    },
    "totalDisplay": {
      "type": "binding",
      "template": "$${orderTotal}"
    }
  },

  "actions": {
    "incrementTaco": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "tacoCount", "value": { "$expr": "${tacoCount} + 1" } },
        { "type": "setState", "path": "orderTotal", "value": { "$expr": "${orderTotal} + 4.50" } }
      ]
    },
    "decrementTaco": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "tacoCount", "value": { "$expr": "${tacoCount} - 1" } },
        { "type": "setState", "path": "orderTotal", "value": { "$expr": "${orderTotal} - 4.50" } }
      ]
    },
    "incrementBurrito": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "burritoCount", "value": { "$expr": "${burritoCount} + 1" } },
        { "type": "setState", "path": "orderTotal", "value": { "$expr": "${orderTotal} + 9.50" } }
      ]
    },
    "decrementBurrito": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "burritoCount", "value": { "$expr": "${burritoCount} - 1" } },
        { "type": "setState", "path": "orderTotal", "value": { "$expr": "${orderTotal} - 9.50" } }
      ]
    },
    "selectCarnitas": {
      "type": "setState",
      "path": "selectedProtein",
      "value": "Carnitas"
    },
    "selectPollo": {
      "type": "setState",
      "path": "selectedProtein",
      "value": "Pollo"
    },
    "selectCarne": {
      "type": "setState",
      "path": "selectedProtein",
      "value": "Carne Asada"
    },
    "selectVeggie": {
      "type": "setState",
      "path": "selectedProtein",
      "value": "Veggie"
    },
    "placeOrder": {
      "type": "showAlert",
      "title": "Order Placed!",
      "message": {
        "type": "binding",
        "template": "Thanks ${customerName}! Your ${tacoCount} taco(s) and ${burritoCount} burrito(s) with ${selectedProtein} will be ready soon. Total: $${orderTotal}"
      },
      "buttons": [
        { "label": "Awesome!", "style": "default" }
      ]
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 0,
        "children": [
          {
            "type": "vstack",
            "spacing": 20,
            "padding": { "horizontal": 20, "top": 20, "bottom": 20 },
            "children": [
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "label", "label": "🌮", "styleId": "emoji" },
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "label": "Taco Truck", "styleId": "screenTitle" },
                      { "type": "label", "label": "Fresh & Delicious", "styleId": "menuItemPrice" }
                    ]
                  },
                  { "type": "spacer" },
                  { "type": "label", "label": "🔥", "styleId": "emoji" }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 8,
                "children": [
                  { "type": "label", "label": "Your Name", "styleId": "sectionTitle" },
                  {
                    "type": "textfield",
                    "placeholder": "Enter your name...",
                    "bind": "customerName",
                    "styleId": "inputField"
                  }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 12,
                "children": [
                  { "type": "label", "label": "Menu", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 16,
                    "children": [
                      { "type": "label", "label": "🌮", "styleId": "emoji" },
                      {
                        "type": "vstack",
                        "alignment": "leading",
                        "spacing": 2,
                        "children": [
                          { "type": "label", "label": "Street Taco", "styleId": "menuItemTitle" },
                          { "type": "label", "label": "$4.50 each", "styleId": "menuItemPrice" }
                        ]
                      },
                      { "type": "spacer" },
                      {
                        "type": "hstack",
                        "spacing": 12,
                        "children": [
                          {
                            "type": "button",
                            "label": "−",
                            "styleId": "countButton",
                            "actions": { "onTap": "decrementTaco" }
                          },
                          {
                            "type": "label",
                            "dataSourceId": "tacoCountDisplay",
                            "styleId": "countDisplay"
                          },
                          {
                            "type": "button",
                            "label": "+",
                            "styleId": "countButton",
                            "actions": { "onTap": "incrementTaco" }
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 16,
                    "children": [
                      { "type": "label", "label": "🌯", "styleId": "emoji" },
                      {
                        "type": "vstack",
                        "alignment": "leading",
                        "spacing": 2,
                        "children": [
                          { "type": "label", "label": "Burrito Grande", "styleId": "menuItemTitle" },
                          { "type": "label", "label": "$9.50 each", "styleId": "menuItemPrice" }
                        ]
                      },
                      { "type": "spacer" },
                      {
                        "type": "hstack",
                        "spacing": 12,
                        "children": [
                          {
                            "type": "button",
                            "label": "−",
                            "styleId": "countButton",
                            "actions": { "onTap": "decrementBurrito" }
                          },
                          {
                            "type": "label",
                            "dataSourceId": "burritoCountDisplay",
                            "styleId": "countDisplay"
                          },
                          {
                            "type": "button",
                            "label": "+",
                            "styleId": "countButton",
                            "actions": { "onTap": "incrementBurrito" }
                          }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 12,
                "children": [
                  { "type": "label", "label": "Choose Your Protein", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "label": "🐷 Carnitas",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectCarnitas" }
                      },
                      {
                        "type": "button",
                        "label": "🐔 Pollo",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectPollo" }
                      }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "label": "🥩 Carne Asada",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectCarne" }
                      },
                      {
                        "type": "button",
                        "label": "🥬 Veggie",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectVeggie" }
                      }
                    ]
                  }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 8,
                "children": [
                  { "type": "label", "label": "Special Instructions", "styleId": "sectionTitle" },
                  {
                    "type": "textfield",
                    "placeholder": "Extra salsa, no onions, etc...",
                    "bind": "specialInstructions",
                    "styleId": "inputField"
                  }
                ]
              }
            ]
          },
          { "type": "spacer" },
          {
            "type": "vstack",
            "spacing": 16,
            "padding": { "horizontal": 20, "bottom": 20 },
            "children": [
              {
                "type": "hstack",
                "children": [
                  { "type": "label", "label": "Order Total", "styleId": "totalLabel" },
                  { "type": "spacer" },
                  { "type": "label", "dataSourceId": "totalDisplay", "styleId": "totalAmount" }
                ]
              },
              {
                "type": "button",
                "label": "Place Order 🎉",
                "styleId": "orderButton",
                "fillWidth": true,
                "actions": { "onTap": "placeOrder" }
              }
            ]
          }
        ]
      }
    ]
  }
}
"""

// MARK: - Movie Night Example (UIKit Renderer + Delegate Pattern)

import UIKit

/// Example demonstrating:
/// - CladsUIKitView with UIViewControllerRepresentable
/// - CladsRendererDelegate for callbacks
/// - State monitoring via delegate methods
struct MovieNightExampleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var delegateEvents: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            // UIKit-rendered CLADS view
            MovieNightUIKitView(
                onDismiss: { dismiss() },
                onEvent: { event in
                    delegateEvents.append(event)
                    if delegateEvents.count > 8 {
                        delegateEvents.removeFirst()
                    }
                }
            )
            .frame(maxHeight: .infinity)

            Divider()

            // Debug panel showing delegate events
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("UIKit Delegate Events")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "apple.logo")
                        .foregroundStyle(.secondary)
                    Text("UIKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if delegateEvents.isEmpty {
                    Text("Interact with the view to see delegate events...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(delegateEvents.enumerated()), id: \.offset) { _, event in
                                Text(event)
                                    .font(.caption2)
                                    .fontDesign(.monospaced)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
            }
            .padding()
            .background(.regularMaterial)
        }
    }
}

/// UIViewControllerRepresentable that hosts a CladsViewController
struct MovieNightUIKitView: UIViewControllerRepresentable {
    let onDismiss: () -> Void
    let onEvent: (String) -> Void

    func makeUIViewController(context: Context) -> MovieNightViewController {
        let vc = MovieNightViewController(jsonString: movieNightJSON)!
        vc.onDismiss = onDismiss
        vc.onEvent = onEvent
        return vc
    }

    func updateUIViewController(_ uiViewController: MovieNightViewController, context: Context) {}
}

/// Custom CladsViewController subclass demonstrating delegate pattern
final class MovieNightViewController: CladsViewController {
    var onDismiss: (() -> Void)?
    var onEvent: ((String) -> Void)?

    override func cladsRenderer(_ view: CladsUIKitView, didChangeState path: String, from oldValue: Any?, to newValue: Any?) {
        let newStr = newValue.map { String(describing: $0) } ?? "nil"
        onEvent?("setState: \(path) = \(newStr)")
    }

    override func cladsRenderer(_ view: CladsUIKitView, willExecuteAction actionId: String) {
        onEvent?("willExecute: \(actionId)")
    }

    override func cladsRenderer(_ view: CladsUIKitView, didExecuteAction actionId: String) {
        onEvent?("didExecute: \(actionId)")
    }

    override func cladsRendererDidRequestDismiss(_ view: CladsUIKitView) {
        onEvent?("dismiss requested")
        onDismiss?()
    }

    override func cladsRenderer(_ view: CladsUIKitView, didRequestAlert config: AlertConfiguration) {
        onEvent?("alert: \(config.title)")
        super.cladsRenderer(view, didRequestAlert: config)
    }
}

private let movieNightJSON = """
{
  "id": "movie-night-picker",
  "version": "1.0",

  "state": {
    "selectedGenre": "Action",
    "movieTitle": "",
    "rating": 5,
    "includeSnacks": true,
    "attendees": 2
  },

  "actions": {
    "dismissView": { "type": "dismiss" },
    "selectAction": { "type": "setState", "path": "selectedGenre", "value": "Action" },
    "selectComedy": { "type": "setState", "path": "selectedGenre", "value": "Comedy" },
    "selectHorror": { "type": "setState", "path": "selectedGenre", "value": "Horror" },
    "selectSciFi": { "type": "setState", "path": "selectedGenre", "value": "Sci-Fi" },
    "incrementAttendees": {
      "type": "setState",
      "path": "attendees",
      "value": { "$expr": "${attendees} + 1" }
    },
    "decrementAttendees": {
      "type": "setState",
      "path": "attendees",
      "value": { "$expr": "${attendees} - 1" }
    },
    "incrementRating": {
      "type": "setState",
      "path": "rating",
      "value": { "$expr": "${rating} + 1" }
    },
    "decrementRating": {
      "type": "setState",
      "path": "rating",
      "value": { "$expr": "${rating} - 1" }
    },
    "startMovie": {
      "type": "showAlert",
      "title": "Lights, Camera, Action!",
      "message": {
        "type": "binding",
        "template": "Starting ${selectedGenre} movie night with ${attendees} people. Enjoy!"
      },
      "buttons": [{ "label": "Let's Go!", "style": "default" }]
    }
  },

  "styles": {
    "screenTitle": {
      "fontSize": 32,
      "fontWeight": "bold",
      "textColor": "#FFFFFF"
    },
    "subtitle": {
      "fontSize": 16,
      "fontWeight": "regular",
      "textColor": "#AAAAAA"
    },
    "sectionTitle": {
      "fontSize": 18,
      "fontWeight": "semibold",
      "textColor": "#FFFFFF"
    },
    "genreButton": {
      "fontSize": 14,
      "fontWeight": "medium",
      "backgroundColor": "#2A2A2A",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 44
    },
    "genreSelected": {
      "fontSize": 14,
      "fontWeight": "bold",
      "backgroundColor": "#E50914",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 44
    },
    "countButton": {
      "fontSize": 20,
      "fontWeight": "bold",
      "backgroundColor": "#2A2A2A",
      "textColor": "#E50914",
      "cornerRadius": 8,
      "width": 44,
      "height": 44
    },
    "countDisplay": {
      "fontSize": 24,
      "fontWeight": "bold",
      "textColor": "#FFFFFF"
    },
    "label": {
      "fontSize": 16,
      "fontWeight": "medium",
      "textColor": "#FFFFFF"
    },
    "inputField": {
      "fontSize": 16,
      "textColor": "#FFFFFF",
      "backgroundColor": "#2A2A2A",
      "cornerRadius": 10
    },
    "startButton": {
      "fontSize": 18,
      "fontWeight": "bold",
      "backgroundColor": "#E50914",
      "textColor": "#FFFFFF",
      "cornerRadius": 14,
      "height": 56
    },
    "closeButton": {
      "fontSize": 17,
      "fontWeight": "medium",
      "textColor": "#E50914"
    },
    "emoji": {
      "fontSize": 40
    }
  },

  "dataSources": {
    "attendeesDisplay": { "type": "binding", "path": "attendees" },
    "ratingDisplay": { "type": "binding", "path": "rating" }
  },

  "root": {
    "backgroundColor": "#141414",
    "children": [
      {
        "type": "vstack",
        "spacing": 0,
        "children": [
          {
            "type": "hstack",
            "padding": { "horizontal": 20, "top": 20 },
            "children": [
              { "type": "spacer" },
              {
                "type": "button",
                "label": "Close",
                "styleId": "closeButton",
                "actions": { "onTap": "dismissView" }
              }
            ]
          },
          {
            "type": "vstack",
            "spacing": 24,
            "padding": { "horizontal": 20, "top": 8, "bottom": 20 },
            "children": [
              {
                "type": "hstack",
                "spacing": 16,
                "children": [
                  { "type": "label", "label": "🎬", "styleId": "emoji" },
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "label": "Movie Night", "styleId": "screenTitle" },
                      { "type": "label", "label": "Pick your perfect movie experience", "styleId": "subtitle" }
                    ]
                  },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 12,
                "children": [
                  { "type": "label", "label": "Choose Genre", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "label": "Action",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectAction" }
                      },
                      {
                        "type": "button",
                        "label": "Comedy",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectComedy" }
                      }
                    ]
                  },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "label": "Horror",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectHorror" }
                      },
                      {
                        "type": "button",
                        "label": "Sci-Fi",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectSciFi" }
                      }
                    ]
                  }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 8,
                "children": [
                  { "type": "label", "label": "Movie Title (optional)", "styleId": "sectionTitle" },
                  {
                    "type": "textfield",
                    "placeholder": "Enter a movie name...",
                    "bind": "movieTitle",
                    "styleId": "inputField"
                  }
                ]
              },
              {
                "type": "hstack",
                "spacing": 20,
                "children": [
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 8,
                    "children": [
                      { "type": "label", "label": "Attendees", "styleId": "sectionTitle" },
                      {
                        "type": "hstack",
                        "spacing": 16,
                        "children": [
                          {
                            "type": "button",
                            "label": "−",
                            "styleId": "countButton",
                            "actions": { "onTap": "decrementAttendees" }
                          },
                          {
                            "type": "label",
                            "dataSourceId": "attendeesDisplay",
                            "styleId": "countDisplay"
                          },
                          {
                            "type": "button",
                            "label": "+",
                            "styleId": "countButton",
                            "actions": { "onTap": "incrementAttendees" }
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 8,
                    "children": [
                      { "type": "label", "label": "Min Rating", "styleId": "sectionTitle" },
                      {
                        "type": "hstack",
                        "spacing": 16,
                        "children": [
                          {
                            "type": "button",
                            "label": "−",
                            "styleId": "countButton",
                            "actions": { "onTap": "decrementRating" }
                          },
                          {
                            "type": "label",
                            "dataSourceId": "ratingDisplay",
                            "styleId": "countDisplay"
                          },
                          {
                            "type": "button",
                            "label": "+",
                            "styleId": "countButton",
                            "actions": { "onTap": "incrementRating" }
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },
          { "type": "spacer" },
          {
            "type": "vstack",
            "padding": { "horizontal": 20, "bottom": 20 },
            "children": [
              {
                "type": "button",
                "label": "Start Movie Night",
                "styleId": "startButton",
                "fillWidth": true,
                "actions": { "onTap": "startMovie" }
              }
            ]
          }
        ]
      }
    ]
  }
}
"""

#Preview {
    ContentView()
}

#Preview("Taco Truck") {
    TacoTruckExampleView()
}

#Preview("Movie Night") {
    MovieNightExampleView()
}
