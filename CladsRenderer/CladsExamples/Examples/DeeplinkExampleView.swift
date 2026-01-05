//
//  DeeplinkExampleView.swift
//  CladsExamples
//
//  Example demonstrating deeplink navigation with tab switching and sheet presentation.
//

import CLADS
import CladsModules
import SwiftUI
import UIKit

// MARK: - Deeplink Example View

/// Example demonstrating:
/// - Deeplink URL structure
/// - Tab navigation via deeplinks
/// - Sheet presentation from deeplinks
/// - Custom parameters in deeplink URLs
public struct DeeplinkExampleView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        if let document = try? Document.Definition(jsonString: deeplinkExampleJSON) {
            CladsRendererView(
                document: document,
                customActions: [
                    "openDeeplink": { [dismiss] params, _ in
                        guard let urlString = params.string("url"),
                              let url = URL(string: urlString) else {
                            return
                        }
                        await MainActor.run {
                            // Dismiss the example view first
                            dismiss()
                            // Then open the deeplink after a short delay for dismiss animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                UIApplication.shared.open(url)
                            }
                        }
                    },
                    "copyDeeplink": { params, _ in
                        guard let urlString = params.string("url") else { return }
                        await MainActor.run {
                            UIPasteboard.general.string = urlString
                        }
                    }
                ]
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Failed to parse Deeplink JSON")
                    .foregroundStyle(.secondary)
                Button("Dismiss") { dismiss() }
            }
        }
    }
}

// MARK: - JSON

let deeplinkExampleJSON = """
{
  "id": "deeplink-example",
  "version": "1.0",

  "state": {
    "copiedUrl": ""
  },

  "styles": {
    "screenTitle": { "fontSize": 28, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 15, "textColor": "#8E8E93" },
    "sectionTitle": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#000000" },
    "cardStyle": {
      "backgroundColor": "#F2F2F7",
      "cornerRadius": 16,
      "padding": { "all": 16 }
    },
    "urlLabel": {
      "fontSize": 13,
      "fontWeight": "medium",
      "textColor": "#007AFF",
      "backgroundColor": "#007AFF15",
      "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 8 }
    },
    "description": { "fontSize": 14, "textColor": "#666666" },
    "openButton": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 12, "height": 48
    },
    "copyButton": {
      "fontSize": 14, "fontWeight": "medium",
      "backgroundColor": "#E5E5EA", "textColor": "#007AFF",
      "cornerRadius": 10, "height": 40
    },
    "infoIcon": { "width": 20, "height": 20, "tintColor": "#8E8E93" },
    "infoText": { "fontSize": 13, "textColor": "#8E8E93" }
  },

  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 20 },
    "children": [{
      "type": "sectionLayout",
      "sectionSpacing": 24,
      "sections": [
        {
          "id": "header",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "children": [
            {
              "type": "vstack",
              "alignment": "leading",
              "spacing": 8,
              "children": [
                { "type": "label", "text": "Deeplinks", "styleId": "screenTitle" },
                { "type": "label", "text": "Test deeplink navigation and sheet presentation", "styleId": "subtitle" }
              ]
            }
          ]
        },
        {
          "id": "example1",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "header": { "type": "label", "text": "Dashboard + Sheet", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
          "children": [
            {
              "type": "vstack",
              "spacing": 16,
              "styleId": "cardStyle",
              "children": [
                {
                  "type": "vstack",
                  "spacing": 8,
                  "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "ghost://dashboard/examples/sheet?title=Hello&message=World", "styleId": "urlLabel" },
                    { "type": "label", "text": "Switches to the Dashboard tab and opens a bottom sheet with custom title and message.", "styleId": "description" }
                  ]
                },
                {
                  "type": "hstack",
                  "spacing": 12,
                  "children": [
                    {
                      "type": "button",
                      "text": "Open Deeplink",
                      "styleId": "openButton",
                      "fillWidth": true,
                      "actions": {
                        "onTap": { "type": "openDeeplink", "url": "ghost://dashboard/examples/sheet?title=Hello&message=World" }
                      }
                    },
                    {
                      "type": "button",
                      "text": "Copy",
                      "styleId": "copyButton",
                      "actions": {
                        "onTap": { "type": "copyDeeplink", "url": "ghost://dashboard/examples/sheet?title=Hello&message=World" }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "id": "example2",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "header": { "type": "label", "text": "Weather City Change", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
          "children": [
            {
              "type": "vstack",
              "spacing": 16,
              "styleId": "cardStyle",
              "children": [
                {
                  "type": "vstack",
                  "spacing": 8,
                  "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "ghost://dashboard/weather/city?name=Seattle", "styleId": "urlLabel" },
                    { "type": "label", "text": "Switches to Dashboard and changes the weather widget location to Seattle.", "styleId": "description" }
                  ]
                },
                {
                  "type": "hstack",
                  "spacing": 12,
                  "children": [
                    {
                      "type": "button",
                      "text": "Open Deeplink",
                      "styleId": "openButton",
                      "fillWidth": true,
                      "actions": {
                        "onTap": { "type": "openDeeplink", "url": "ghost://dashboard/weather/city?name=Seattle" }
                      }
                    },
                    {
                      "type": "button",
                      "text": "Copy",
                      "styleId": "copyButton",
                      "actions": {
                        "onTap": { "type": "copyDeeplink", "url": "ghost://dashboard/weather/city?name=Seattle" }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "id": "example3",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "header": { "type": "label", "text": "Custom Message", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
          "children": [
            {
              "type": "vstack",
              "spacing": 16,
              "styleId": "cardStyle",
              "children": [
                {
                  "type": "vstack",
                  "spacing": 8,
                  "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "ghost://dashboard/examples/sheet?title=Welcome&message=This%20is%20a%20custom%20message", "styleId": "urlLabel" },
                    { "type": "label", "text": "Demonstrates URL-encoded parameters for spaces and special characters.", "styleId": "description" }
                  ]
                },
                {
                  "type": "hstack",
                  "spacing": 12,
                  "children": [
                    {
                      "type": "button",
                      "text": "Open Deeplink",
                      "styleId": "openButton",
                      "fillWidth": true,
                      "actions": {
                        "onTap": { "type": "openDeeplink", "url": "ghost://dashboard/examples/sheet?title=Welcome&message=This%20is%20a%20custom%20message" }
                      }
                    },
                    {
                      "type": "button",
                      "text": "Copy",
                      "styleId": "copyButton",
                      "actions": {
                        "onTap": { "type": "copyDeeplink", "url": "ghost://dashboard/examples/sheet?title=Welcome&message=This%20is%20a%20custom%20message" }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "id": "info",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20, "bottom": 40 } },
          "children": [
            {
              "type": "hstack",
              "spacing": 8,
              "alignment": { "vertical": "top" },
              "padding": { "all": 16 },
              "children": [
                { "type": "image", "image": { "system": "info.circle" }, "styleId": "infoIcon" },
                { "type": "label", "text": "Deeplinks use the format: ghost://[tab]/[feature]/[action]?[params]. The router switches to the specified tab, then delegates to the feature handler.", "styleId": "infoText" }
              ]
            }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: - Preview

#Preview {
    DeeplinkExampleView()
}
