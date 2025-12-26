//
//  ContentView.swift
//  CladsRenderer
//

import SwiftUI
import CladsRendererFramework

struct ContentView: View {
    var body: some View {
        if let view = CladsRendererView(jsonString: sampleJSON, debugMode: true) {
            view
        } else {
            Text("Failed to parse JSON")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Sample JSON

private let sampleJSON = """
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

#Preview {
    ContentView()
}
