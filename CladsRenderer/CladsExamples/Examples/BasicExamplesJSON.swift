//
//  BasicExamplesJSON.swift
//  CladsRenderer
//
//  JSON definitions for basic examples that use ExampleSheetView.
//

import Foundation

// MARK: - Component Showcase

public let componentShowcaseJSON = """
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
        "sectionSpacing": 52,
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

// MARK: - Basic Example

public let basicExampleJSON = """
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

// MARK: - Section Layout

public let sectionLayoutJSON = """
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

// MARK: - Interests (Flow Layout with Array State)

public let interestsJSON = """
{
  "id": "interests-picker",
  "version": "1.0",

  "state": {
    "selectedInterests": []
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
    "countStyle": {
      "fontSize": 14,
      "fontWeight": "medium",
      "textColor": "#007AFF"
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
              { "type": "label", "text": "Select topics you'd like to follow", "styleId": "subtitleStyle" },
              {
                "type": "label",
                "data": { "value": { "type": "binding", "template": "${selectedInterests.count} selected" } },
                "styleId": "countStyle"
              }
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
                    "isSelectedBinding": "${selectedInterests.contains('Technology')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Technology" } }
                  },
                  {
                    "type": "button",
                    "text": "Sports",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Sports')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Sports" } }
                  },
                  {
                    "type": "button",
                    "text": "Music",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Music')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Music" } }
                  },
                  {
                    "type": "button",
                    "text": "Art & Design",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Art & Design')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Art & Design" } }
                  },
                  {
                    "type": "button",
                    "text": "Travel",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Travel')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Travel" } }
                  },
                  {
                    "type": "button",
                    "text": "Food",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Food')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Food" } }
                  },
                  {
                    "type": "button",
                    "text": "Gaming",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Gaming')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Gaming" } }
                  },
                  {
                    "type": "button",
                    "text": "Fitness",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Fitness')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Fitness" } }
                  },
                  {
                    "type": "button",
                    "text": "Photography",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Photography')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Photography" } }
                  },
                  {
                    "type": "button",
                    "text": "Movies",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Movies')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Movies" } }
                  },
                  {
                    "type": "button",
                    "text": "Books",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Books')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Books" } }
                  },
                  {
                    "type": "button",
                    "text": "Science",
                    "styles": { "normal": "pillButton", "selected": "pillButtonSelected" },
                    "isSelectedBinding": "${selectedInterests.contains('Science')}",
                    "actions": { "onTap": { "type": "toggleInArray", "path": "selectedInterests", "value": "Science" } }
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
