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
                Group {
                    switch example {
                    case .dadJokes:
                        DadJokesExampleView()
                    case .tacoTruck:
                        TacoTruckExampleView()
                    case .movieNight:
                        MovieNightExampleView()
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
    case favoritePlaces
    case sectionLayout
    case interests
    case dadJokes
    case tacoTruck
    case movieNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .componentShowcase: return "Component Showcase"
        case .basic: return "Basic Example"
        case .favoritePlaces: return "Favorite Places"
        case .sectionLayout: return "Section Layout"
        case .interests: return "Interests"
        case .dadJokes: return "Dad Jokes"
        case .tacoTruck: return "Taco Truck"
        case .movieNight: return "Movie Night"
        }
    }

    var subtitle: String? {
        switch self {
        case .componentShowcase: return "All component types"
        case .basic: return "Welcome screen with actions"
        case .favoritePlaces: return "Hero image with gradient"
        case .sectionLayout: return "Horizontal, grid, and list"
        case .interests: return "Flow layout with selectable pills"
        case .dadJokes: return "Custom actions with REST API"
        case .tacoTruck: return "Typed state, callbacks, binding API"
        case .movieNight: return "UIKit renderer with delegate"
        }
    }

    var icon: String {
        switch self {
        case .componentShowcase: return "square.stack.3d.up"
        case .basic: return "sparkles"
        case .favoritePlaces: return "mappin.and.ellipse"
        case .sectionLayout: return "square.grid.2x2"
        case .interests: return "heart.circle"
        case .dadJokes: return "face.smiling"
        case .tacoTruck: return "fork.knife"
        case .movieNight: return "film"
        }
    }

    var iconColor: Color {
        switch self {
        case .componentShowcase: return .indigo
        case .basic: return .blue
        case .favoritePlaces: return .green
        case .sectionLayout: return .purple
        case .interests: return .pink
        case .dadJokes: return .yellow
        case .tacoTruck: return .orange
        case .movieNight: return .red
        }
    }

    var json: String {
        switch self {
        case .componentShowcase: return componentShowcaseJSON
        case .basic: return basicExampleJSON
        case .favoritePlaces: return favoritePlacesJSON
        case .sectionLayout: return sectionLayoutJSON
        case .interests: return interestsJSON
        case .dadJokes: return dadJokesJSON
        case .tacoTruck: return tacoTruckJSON
        case .movieNight: return movieNightJSON
        }
    }

    var presentation: PresentationStyle {
        switch self {
        case .componentShowcase: return .fullScreen
        case .basic: return .autoSize
        case .favoritePlaces: return .detent(.medium)
        case .sectionLayout: return .fullScreen
        case .interests: return .detent(.medium)
        case .dadJokes: return .detent(.medium)
        case .tacoTruck: return .fullSize
        case .movieNight: return .fullScreen
        }
    }

    static var basicExamples: [Example] {
        [.componentShowcase, .basic, .favoritePlaces, .sectionLayout, .interests]
    }

    static var advancedExamples: [Example] {
        [.dadJokes, .tacoTruck, .movieNight]
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

// MARK: - Component Showcase Example

private let componentShowcaseJSON = """
{
  "id": "component-showcase",
  "version": "1.0",

  "state": {
    "textFieldValue": "",
    "buttonTapCount": 0,
    "isToggled": false,
    "toggle1": false,
    "toggle2": true,
    "toggle3": false,
    "slider1": 0.5,
    "slider2": 0.75,
    "slider3": 25
  },

  "styles": {
    "screenTitle": {
      "fontSize": 28,
      "fontWeight": "bold",
      "textColor": "#000000",
      "textAlignment": "leading"
    },
    "sectionTitle": {
      "fontSize": 18,
      "fontWeight": "semibold",
      "textColor": "#000000"
    },
    "bodyText": {
      "fontSize": 15,
      "fontWeight": "regular",
      "textColor": "#333333"
    },
    "captionText": {
      "fontSize": 13,
      "fontWeight": "regular",
      "textColor": "#888888"
    },
    "primaryButton": {
      "fontSize": 16,
      "fontWeight": "semibold",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 10,
      "height": 44,
      "padding": { "horizontal": 20 }
    },
    "secondaryButton": {
      "fontSize": 16,
      "fontWeight": "medium",
      "backgroundColor": "#E5E5EA",
      "textColor": "#000000",
      "cornerRadius": 10,
      "height": 44,
      "padding": { "horizontal": 20 }
    },
    "toggleButton": {
      "fontSize": 14,
      "fontWeight": "medium",
      "backgroundColor": "#E5E5EA",
      "textColor": "#000000",
      "cornerRadius": 8,
      "height": 36,
      "padding": { "horizontal": 16 }
    },
    "toggleButtonSelected": {
      "fontSize": 14,
      "fontWeight": "semibold",
      "backgroundColor": "#34C759",
      "textColor": "#FFFFFF",
      "cornerRadius": 8,
      "height": 36,
      "padding": { "horizontal": 16 }
    },
    "textFieldStyle": {
      "fontSize": 16,
      "fontWeight": "regular",
      "textColor": "#000000",
      "backgroundColor": "#F2F2F7",
      "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 12 }
    },
    "iconStyle": {
      "width": 48,
      "height": 48
    },
    "largeIconStyle": {
      "width": 60,
      "height": 60
    },
    "redIconStyle": {
      "inherits": "iconStyle",
      "tintColor": "#FF3B30"
    },
    "orangeIconStyle": {
      "inherits": "iconStyle",
      "tintColor": "#FF9500"
    },
    "blueIconStyle": {
      "inherits": "iconStyle",
      "tintColor": "#007AFF"
    },
    "urlImageStyle": {
      "cornerRadius": 12
    },
    "greenToggleStyle": {
      "tintColor": "#34C759"
    },
    "purpleToggleStyle": {
      "tintColor": "#AF52DE"
    },
    "orangeSliderStyle": {
      "tintColor": "#FF9500"
    },
    "redSliderStyle": {
      "tintColor": "#FF3B30"
    },
    "cardStyle": {
      "backgroundColor": "#F2F2F7",
      "cornerRadius": 12,
      "padding": { "all": 16 }
    },
    "gradientStyle": {
      "width": 320,
      "height": 80,
      "cornerRadius": 12
    },
    "gradientLabel": {
      "fontSize": 16,
      "fontWeight": "semibold",
      "textColor": "#FFFFFF"
    },
    "closeButton": {
      "fontSize": 15,
      "fontWeight": "regular",
      "textColor": "#007AFF"
    }
  },

  "actions": {
    "incrementCount": {
      "type": "setState",
      "path": "buttonTapCount",
      "value": { "$expr": "${buttonTapCount} + 1" }
    },
    "close": {
      "type": "dismiss"
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": {
      "top": 16
    },
    "children": [
      {
        "type": "sectionLayout",
        "sectionSpacing": 32,
        "sections": [
          {
            "id": "header",
            "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
            "children": [
              {
                "type": "hstack",
                "children": [
                  { "type": "spacer" },
                  {
                    "type": "button",
                    "text": "Close",
                    "styleId": "closeButton",
                    "actions": { "onTap": "close" }
                  }
                ]
              },
              { "type": "label", "text": "Component Showcase", "styleId": "screenTitle" },
              { "type": "label", "text": "This example demonstrates all available component types in CladsRenderer.", "styleId": "bodyText" }
            ]
          },
          {
            "id": "labels",
            "layout": { "type": "list", "showsDividers": false, "itemSpacing": 8, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Labels", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              { "type": "label", "text": "This is body text with regular weight.", "styleId": "bodyText" },
              { "type": "label", "text": "This is caption text, smaller and lighter.", "styleId": "captionText" }
            ]
          },
          {
            "id": "buttons",
            "layout": { "type": "list", "showsDividers": false, "itemSpacing": 12, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Buttons", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  {
                    "type": "button",
                    "text": "Primary",
                    "styleId": "primaryButton",
                    "actions": { "onTap": "incrementCount" }
                  },
                  {
                    "type": "button",
                    "text": "Secondary",
                    "styleId": "secondaryButton",
                    "actions": { "onTap": "incrementCount" }
                  }
                ]
              },
              {
                "type": "hstack",
                "spacing": 8,
                "children": [
                  { "type": "label", "text": "Tap count:", "styleId": "captionText" },
                  { "type": "label", "dataSourceId": "tapCountText", "styleId": "captionText" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "label", "text": "Toggle:", "styleId": "bodyText" },
                  {
                    "type": "button",
                    "text": "Off / On",
                    "styles": { "normal": "toggleButton", "selected": "toggleButtonSelected" },
                    "isSelectedBinding": "isToggled",
                    "actions": { "onTap": { "type": "toggleState", "path": "isToggled" } }
                  }
                ]
              }
            ]
          },
          {
            "id": "textfield",
            "layout": { "type": "list", "showsDividers": false, "itemSpacing": 8, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Text Field", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "textfield",
                "placeholder": "Enter some text...",
                "styleId": "textFieldStyle",
                "bind": "textFieldValue"
              },
              {
                "type": "hstack",
                "spacing": 8,
                "children": [
                  { "type": "label", "text": "You typed:", "styleId": "captionText" },
                  { "type": "label", "dataSourceId": "textFieldDisplay", "styleId": "captionText" }
                ]
              }
            ]
          },
          {
            "id": "toggles",
            "layout": { "type": "list", "showsDividers": false, "itemSpacing": 16, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Toggles", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "label", "text": "Default toggle:", "styleId": "bodyText" },
                  { "type": "toggle", "bind": "toggle1" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "label", "text": "Green toggle:", "styleId": "bodyText" },
                  { "type": "toggle", "bind": "toggle2", "styleId": "greenToggleStyle" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "children": [
                  { "type": "label", "text": "Purple toggle:", "styleId": "bodyText" },
                  { "type": "toggle", "bind": "toggle3", "styleId": "purpleToggleStyle" }
                ]
              }
            ]
          },
          {
            "id": "sliders",
            "layout": { "type": "list", "showsDividers": false, "itemSpacing": 16, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Sliders", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "vstack",
                "spacing": 8,
                "alignment": "leading",
                "children": [
                  { "type": "label", "text": "Default slider (0-1):", "styleId": "bodyText" },
                  { "type": "slider", "bind": "slider1" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 8,
                "alignment": "leading",
                "children": [
                  { "type": "label", "text": "Orange slider (0-1):", "styleId": "bodyText" },
                  { "type": "slider", "bind": "slider2", "styleId": "orangeSliderStyle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 8,
                "alignment": "leading",
                "children": [
                  { "type": "label", "text": "Red slider (0-100):", "styleId": "bodyText" },
                  { "type": "slider", "bind": "slider3", "minValue": 0, "maxValue": 100, "styleId": "redSliderStyle" }
                ]
              }
            ]
          },
          {
            "id": "images",
            "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
            "header": { "type": "label", "text": "Images", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "hstack",
                "spacing": 16,
                "children": [
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "image", "image": { "system": "star.fill" }, "styleId": "iconStyle" },
                      { "type": "label", "text": "Default", "styleId": "captionText" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "image", "image": { "system": "heart.fill" }, "styleId": "redIconStyle" },
                      { "type": "label", "text": "Red", "styleId": "captionText" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "image", "image": { "system": "bolt.fill" }, "styleId": "orangeIconStyle" },
                      { "type": "label", "text": "Orange", "styleId": "captionText" }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "children": [
                      { "type": "image", "image": { "system": "globe" }, "styleId": "blueIconStyle" },
                      { "type": "label", "text": "Blue", "styleId": "captionText" }
                    ]
                  }
                ]
              },
              { "type": "image", "image": { "url": "https://images.pexels.com/photos/1658967/pexels-photo-1658967.jpeg" }, "styleId": "urlImageStyle" }
            ]
          },
          {
            "id": "gradient",
            "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20, "bottom": 40 } },
            "header": { "type": "label", "text": "Gradient", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
            "children": [
              {
                "type": "zstack",
                "children": [
                  {
                    "type": "gradient",
                    "gradientColors": [
                      { "color": "#FF6B6B", "location": 0.0 },
                      { "color": "#4ECDC4", "location": 0.5 },
                      { "color": "#45B7D1", "location": 1.0 }
                    ],
                    "gradientStart": "leading",
                    "gradientEnd": "trailing",
                    "styleId": "gradientStyle"
                  },
                  {
                    "type": "label",
                    "text": "Gradient Overlay",
                    "styleId": "gradientLabel"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  },

  "dataSources": {
    "tapCountText": {
      "type": "binding",
      "template": "${buttonTapCount}"
    },
    "textFieldDisplay": {
      "type": "binding",
      "template": "${textFieldValue}"
    }
  }
}
"""

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
            { "text": "OK", "style": "default" }
          ]
        }
      ]
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": {
      "bottom": 20
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
                "text": "Got it",
                "styleId": "primaryButton",
                "fillWidth": true,
                "actions": {
                  "onTap": "dismissView"
                }
              },
              {
                "type": "button",
                "id": "notYetButton",
                "text": "Not yet",
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
                "text": "Favorite Places",
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
            "text": "Close",
            "styleId": "closeButton",
            "actions": { "onTap": "dismissView" }
          }
        ]
      },
      {
        "type": "hstack",
        "padding": { "horizontal": 16, "bottom": 8 },
        "children": [
          { "type": "label", "text": "Section Layouts", "styleId": "screenTitle" }
        ]
      },
      {
        "type": "sectionLayout",
        "id": "main-sections",
        "sectionSpacing": 24,
        "sections": [
          {
            "id": "horizontal-section",
            "layout": {
              "type": "horizontal",
              "itemSpacing": 12,
              "contentInsets": { "leading": 16, "trailing": 16 },
              "showsIndicators": false
            },
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "top": 8, "bottom": 8 },
              "children": [
                { "type": "label", "text": "Horizontal Scroll", "styleId": "sectionHeader" }
              ]
            },
            "children": [
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "text": "Item 1", "styleId": "cardTitle" },
                  { "type": "label", "text": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "text": "Item 2", "styleId": "cardTitle" },
                  { "type": "label", "text": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "text": "Item 3", "styleId": "cardTitle" },
                  { "type": "label", "text": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "text": "Item 4", "styleId": "cardTitle" },
                  { "type": "label", "text": "Description", "styleId": "cardSubtitle" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 4,
                "children": [
                  { "type": "label", "text": "Item 5", "styleId": "cardTitle" },
                  { "type": "label", "text": "Description", "styleId": "cardSubtitle" }
                ]
              }
            ]
          },
          {
            "id": "grid-section",
            "layout": {
              "type": "grid",
              "columns": 2,
              "itemSpacing": 12,
              "lineSpacing": 12,
              "contentInsets": { "horizontal": 16 }
            },
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "bottom": 8 },
              "children": [
                { "type": "label", "text": "Grid Layout", "styleId": "sectionHeader" }
              ]
            },
            "children": [
              { "type": "label", "text": "Grid Item 1", "styleId": "cardTitle" },
              { "type": "label", "text": "Grid Item 2", "styleId": "cardTitle" },
              { "type": "label", "text": "Grid Item 3", "styleId": "cardTitle" },
              { "type": "label", "text": "Grid Item 4", "styleId": "cardTitle" }
            ]
          },
          {
            "id": "list-section",
            "layout": {
              "type": "list",
              "itemSpacing": 0,
              "showsDividers": true,
              "contentInsets": { "horizontal": 16 }
            },
            "header": {
              "type": "vstack",
              "alignment": "leading",
              "padding": { "horizontal": 16, "bottom": 8 },
              "children": [
                { "type": "label", "text": "List Layout", "styleId": "sectionHeader" }
              ]
            },
            "children": [
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "text": "List Item 1", "styleId": "cardTitle" },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "text": "List Item 2", "styleId": "cardTitle" },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack",
                "spacing": 12,
                "padding": { "vertical": 12 },
                "children": [
                  { "type": "label", "text": "List Item 3", "styleId": "cardTitle" },
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

// MARK: - Interests Example (Flow Layout with Selection)

private let interestsJSON = """
{
  "id": "interests-picker",
  "version": "1.0",

  "state": {
    "selected.technology": false,
    "selected.sports": false,
    "selected.music": false,
    "selected.artDesign": false,
    "selected.travel": false,
    "selected.food": false,
    "selected.gaming": false,
    "selected.fitness": false,
    "selected.photography": false,
    "selected.movies": false,
    "selected.books": false,
    "selected.science": false
  },

  "styles": {
    "titleStyle": {
      "fontSize": 28,
      "fontWeight": "bold",
      "textColor": "#000000",
      "textAlignment": "leading"
    },
    "subtitleStyle": {
      "fontSize": 15,
      "fontWeight": "regular",
      "textColor": "#666666"
    },
    "pillButton": {
      "fontSize": 15,
      "fontWeight": "medium",
      "backgroundColor": "#F2F2F7",
      "textColor": "#000000",
      "textAlignment": "center",
      "cornerRadius": 20,
      "height": 40,
      "padding": { 
        "horizontal": 22,
        "vertical": 14 
      }
    },
    "pillButtonSelected": {
      "fontSize": 15,
      "fontWeight": "semibold",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "textAlignment": "center",
      "cornerRadius": 20,
      "height": 40,
      "padding": { 
        "horizontal": 22,
        "vertical": 14  
      }
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "children": [
      {
        "type": "vstack",
        "spacing": 20,
        "padding": { "horizontal": 20, "top": 36, "bottom": 20 },
        "children": [
          {
            "type": "vstack",
            "spacing": 8,
            "alignment": "leading",
            "children": [
              { "type": "label", "text": "Choose Your Interests", "styleId": "titleStyle" },
              { "type": "label", "text": "Select topics you'd like to follow", "styleId": "subtitleStyle" }
            ]
          },
          {
            "type": "sectionLayout",
            "sections": [
              {
                "layout": {
                  "type": "flow",
                  "itemSpacing": 10,
                  "lineSpacing": 12
                },
                "children": [
                  {
                    "type": "button",
                    "text": "Technology",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.technology",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.technology" } }
                  },
                  {
                    "type": "button",
                    "text": "Sports",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.sports",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.sports" } }
                  },
                  {
                    "type": "button",
                    "text": "Music",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.music",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.music" } }
                  },
                  {
                    "type": "button",
                    "text": "Art & Design",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.artDesign",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.artDesign" } }
                  },
                  {
                    "type": "button",
                    "text": "Travel",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.travel",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.travel" } }
                  },
                  {
                    "type": "button",
                    "text": "Food",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.food",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.food" } }
                  },
                  {
                    "type": "button",
                    "text": "Gaming",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.gaming",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.gaming" } }
                  },
                  {
                    "type": "button",
                    "text": "Fitness",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.fitness",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.fitness" } }
                  },
                  {
                    "type": "button",
                    "text": "Photography",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.photography",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.photography" } }
                  },
                  {
                    "type": "button",
                    "text": "Movies",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.movies",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.movies" } }
                  },
                  {
                    "type": "button",
                    "text": "Books",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.books",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.books" } }
                  },
                  {
                    "type": "button",
                    "text": "Science",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "selected.science",
                    "actions": { "onTap": { "type": "toggleState", "path": "selected.science" } }
                  }
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

// MARK: - Dad Jokes Example (Custom Actions + REST API)

/// Example demonstrating:
/// - Custom action closures for REST API calls
/// - State updates from network responses
/// - Fun reveal animation with punchline
struct DadJokesExampleView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let document = try? Document.Definition(jsonString: dadJokesJSON) {
                CladsRendererView(
                    document: document,
                    customActions: [
                        // Custom action that fetches a joke from the API
                        "fetchJoke": { params, context in
                            // Set loading state
                            context.stateStore.set("isLoading", value: true)
                            context.stateStore.set("setup", value: "Loading...")
                            context.stateStore.set("punchline", value: "")
                            context.stateStore.set("hiddenPunchline", value: "")

                            do {
                                // Fetch from icanhazdadjoke API
                                var request = URLRequest(url: URL(string: "https://icanhazdadjoke.com/")!)
                                request.setValue("application/json", forHTTPHeaderField: "Accept")

                                let (data, _) = try await URLSession.shared.data(for: request)

                                // Parse response
                                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                                   let joke = json["joke"] as? String {
                                    // Split the joke into setup and punchline
                                    let parts = splitJoke(joke)
                                    context.stateStore.set("setup", value: parts.setup)
                                    // Store punchline hidden
                                    context.stateStore.set("hiddenPunchline", value: parts.punchline)
                                    context.stateStore.set("punchline", value: "")
                                    context.stateStore.set("hasJoke", value: true)
                                }
                            } catch {
                                context.stateStore.set("setup", value: "Couldn't fetch a joke.")
                                context.stateStore.set("punchline", value: "Check your connection and try again.")
                                context.stateStore.set("hiddenPunchline", value: "")
                                context.stateStore.set("hasJoke", value: false)
                            }

                            context.stateStore.set("isLoading", value: false)
                        },

                        // Reveal the punchline by copying from hidden state
                        "revealPunchline": { params, context in
                            if let hidden = context.stateStore.get("hiddenPunchline") as? String,
                               !hidden.isEmpty {
                                context.stateStore.set("punchline", value: hidden)
                                context.stateStore.set("hiddenPunchline", value: "")
                            }
                        }
                    ]
                )
                .navigationTitle("Dad Jokes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
            } else {
                Text("Failed to parse JSON")
                    .foregroundStyle(.red)
            }
        }
    }
}

/// Split a joke into setup and punchline
/// Dad jokes often have a question/answer format or a pause before the punchline
private func splitJoke(_ joke: String) -> (setup: String, punchline: String) {
    // Try to split on question mark (Q&A jokes)
    if let questionIndex = joke.firstIndex(of: "?") {
        let setup = String(joke[...questionIndex])
        let rest = joke[joke.index(after: questionIndex)...]
        let punchline = rest.trimmingCharacters(in: .whitespaces)
        if !punchline.isEmpty {
            return (setup, punchline)
        }
    }

    // Try to split on common pause indicators
    let pauseIndicators = [" - ", "...", ". ", "! "]
    for indicator in pauseIndicators {
        if let range = joke.range(of: indicator, options: .backwards) {
            let setup = String(joke[..<range.lowerBound]) + (indicator == ". " || indicator == "! " ? String(indicator.first!) : "")
            let punchline = String(joke[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !punchline.isEmpty && punchline.count > 5 {
                return (setup, punchline)
            }
        }
    }

    // Fallback: split roughly in half at a space
    let words = joke.split(separator: " ")
    if words.count > 4 {
        let midpoint = words.count / 2
        let setup = words[..<midpoint].joined(separator: " ") + "..."
        let punchline = words[midpoint...].joined(separator: " ")
        return (setup, punchline)
    }

    // Last resort: just show the whole joke
    return (joke, "😄")
}

private let dadJokesJSON = """
{
  "id": "dad-jokes",
  "version": "1.0",

  "state": {
    "setup": "",
    "punchline": "",
    "hiddenPunchline": "",
    "hasJoke": false,
    "isLoading": false
  },

  "styles": {
    "screenTitle": {
      "fontSize": 28,
      "fontWeight": "bold",
      "textColor": "#1a1a1a"
    },
    "jokeSetup": {
      "fontSize": 20,
      "fontWeight": "medium",
      "textColor": "#333333",
      "textAlignment": "center"
    },
    "jokePunchline": {
      "fontSize": 22,
      "fontWeight": "bold",
      "textColor": "#E85D04",
      "textAlignment": "center"
    },
    "placeholderText": {
      "fontSize": 17,
      "fontWeight": "regular",
      "textColor": "#888888",
      "textAlignment": "center"
    },
    "fetchButton": {
      "fontSize": 17,
      "fontWeight": "semibold",
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "cornerRadius": 12,
      "height": 50
    },
    "revealButton": {
      "fontSize": 16,
      "fontWeight": "medium",
      "backgroundColor": "#F2F2F7",
      "textColor": "#007AFF",
      "cornerRadius": 10,
      "height": 44
    },
    "cardStyle": {
      "backgroundColor": "#F9F9F9",
      "cornerRadius": 16
    }
  },

  "dataSources": {
    "setupText": {
      "type": "binding",
      "path": "setup"
    },
    "punchlineText": {
      "type": "binding",
      "path": "punchline"
    }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "actions": {
      "onAppear": { "type": "fetchJoke" }
    },
    "children": [
      {
        "type": "vstack",
        "spacing": 0,
        "children": [
          {
            "type": "vstack",
            "spacing": 24,
            "padding": { "horizontal": 20, "top": 20 },
            "children": [
              {
                "type": "vstack",
                "alignment": "center",
                "spacing": 24,
                "padding": { "all": 24 },
                "styleId": "cardStyle",
                "children": [
                  {
                    "type": "label",
                    "dataSourceId": "setupText",
                    "styleId": "jokeSetup"
                  },
                  {
                    "type": "label",
                    "dataSourceId": "punchlineText",
                    "styleId": "jokePunchline"
                  }
                ]
              }
            ]
          },
          { "type": "spacer" },
          {
            "type": "hstack",
            "spacing": 12,
            "padding": { "horizontal": 20, "bottom": 20 },
            "children": [
              {
                "type": "button",
                "text": "Reveal",
                "styleId": "revealButton",
                "fillWidth": true,
                "actions": { "onTap": "revealPunchline" }
              },
              {
                "type": "button",
                "text": "New Joke",
                "styleId": "fetchButton",
                "fillWidth": true,
                "actions": {
                  "onTap": {
                    "type": "sequence",
                    "steps": [
                      { "type": "fetchJoke" }
                    ]
                  }
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
        { "text": "Awesome!", "style": "default" }
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
                  { "type": "label", "text": "🌮", "styleId": "emoji" },
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Taco Truck", "styleId": "screenTitle" },
                      { "type": "label", "text": "Fresh & Delicious", "styleId": "menuItemPrice" }
                    ]
                  },
                  { "type": "spacer" },
                  { "type": "label", "text": "🔥", "styleId": "emoji" }
                ]
              },
              {
                "type": "vstack",
                "alignment": "leading",
                "spacing": 8,
                "children": [
                  { "type": "label", "text": "Your Name", "styleId": "sectionTitle" },
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
                  { "type": "label", "text": "Menu", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 16,
                    "children": [
                      { "type": "label", "text": "🌮", "styleId": "emoji" },
                      {
                        "type": "vstack",
                        "alignment": "leading",
                        "spacing": 2,
                        "children": [
                          { "type": "label", "text": "Street Taco", "styleId": "menuItemTitle" },
                          { "type": "label", "text": "$4.50 each", "styleId": "menuItemPrice" }
                        ]
                      },
                      { "type": "spacer" },
                      {
                        "type": "hstack",
                        "spacing": 12,
                        "children": [
                          {
                            "type": "button",
                            "text": "−",
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
                            "text": "+",
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
                      { "type": "label", "text": "🌯", "styleId": "emoji" },
                      {
                        "type": "vstack",
                        "alignment": "leading",
                        "spacing": 2,
                        "children": [
                          { "type": "label", "text": "Burrito Grande", "styleId": "menuItemTitle" },
                          { "type": "label", "text": "$9.50 each", "styleId": "menuItemPrice" }
                        ]
                      },
                      { "type": "spacer" },
                      {
                        "type": "hstack",
                        "spacing": 12,
                        "children": [
                          {
                            "type": "button",
                            "text": "−",
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
                            "text": "+",
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
                  { "type": "label", "text": "Choose Your Protein", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "text": "🐷 Carnitas",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectCarnitas" }
                      },
                      {
                        "type": "button",
                        "text": "🐔 Pollo",
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
                        "text": "🥩 Carne Asada",
                        "styleId": "proteinOption",
                        "actions": { "onTap": "selectCarne" }
                      },
                      {
                        "type": "button",
                        "text": "🥬 Veggie",
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
                  { "type": "label", "text": "Special Instructions", "styleId": "sectionTitle" },
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
                  { "type": "label", "text": "Order Total", "styleId": "totalLabel" },
                  { "type": "spacer" },
                  { "type": "label", "dataSourceId": "totalDisplay", "styleId": "totalAmount" }
                ]
              },
              {
                "type": "button",
                "text": "Place Order 🎉",
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
      "buttons": [{ "text": "Let's Go!", "style": "default" }]
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
    "text": {
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
                "text": "Close",
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
                  { "type": "label", "text": "🎬", "styleId": "emoji" },
                  {
                    "type": "vstack",
                    "alignment": "leading",
                    "spacing": 4,
                    "children": [
                      { "type": "label", "text": "Movie Night", "styleId": "screenTitle" },
                      { "type": "label", "text": "Pick your perfect movie experience", "styleId": "subtitle" }
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
                  { "type": "label", "text": "Choose Genre", "styleId": "sectionTitle" },
                  {
                    "type": "hstack",
                    "spacing": 8,
                    "children": [
                      {
                        "type": "button",
                        "text": "Action",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectAction" }
                      },
                      {
                        "type": "button",
                        "text": "Comedy",
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
                        "text": "Horror",
                        "styleId": "genreButton",
                        "actions": { "onTap": "selectHorror" }
                      },
                      {
                        "type": "button",
                        "text": "Sci-Fi",
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
                  { "type": "label", "text": "Movie Title (optional)", "styleId": "sectionTitle" },
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
                      { "type": "label", "text": "Attendees", "styleId": "sectionTitle" },
                      {
                        "type": "hstack",
                        "spacing": 16,
                        "children": [
                          {
                            "type": "button",
                            "text": "−",
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
                            "text": "+",
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
                      { "type": "label", "text": "Min Rating", "styleId": "sectionTitle" },
                      {
                        "type": "hstack",
                        "spacing": 16,
                        "children": [
                          {
                            "type": "button",
                            "text": "−",
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
                            "text": "+",
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
                "text": "Start Movie Night",
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

#Preview("Dad Jokes") {
    DadJokesExampleView()
}

#Preview("Taco Truck") {
    TacoTruckExampleView()
}

#Preview("Movie Night") {
    MovieNightExampleView()
}
