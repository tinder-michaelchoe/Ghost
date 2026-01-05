//
//  CLADSExamplesJSON.swift
//  CladsRenderer
//
//  JSON definitions for CLADS-organized examples.
//  Each example focuses on demonstrating a specific feature.
//

import Foundation

// MARK: - Components (C)

// MARK: Labels

let labelsJSON = """
{
  "id": "labels-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 24, "fontWeight": "bold", "textColor": "#000000" },
    "body": { "fontSize": 16, "fontWeight": "regular", "textColor": "#333333" },
    "caption": { "fontSize": 12, "fontWeight": "light", "textColor": "#888888" },
    "centered": { "fontSize": 16, "textAlignment": "center", "textColor": "#007AFF" },
    "multiline": { "fontSize": 14, "textColor": "#333333", "numberOfLines": 3 }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Title Label", "styleId": "title" },
        { "type": "label", "text": "Body text with regular weight and dark gray color.", "styleId": "body" },
        { "type": "label", "text": "Caption - smaller and lighter", "styleId": "caption" },
        { "type": "hstack", "children": [{ "type": "spacer" }, { "type": "label", "text": "Centered Text", "styleId": "centered" }, { "type": "spacer" }] },
        { "type": "label", "text": "This is a multiline label that can wrap to multiple lines when the text is too long to fit on a single line.", "styleId": "multiline" }
      ]
    }]
  }
}
"""

// MARK: Buttons

let buttonsJSON = """
{
  "id": "buttons-example",
  "version": "1.0",
  "state": { "tapCount": 0 },
  "styles": {
    "primary": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 20 }
    },
    "secondary": {
      "fontSize": 16, "fontWeight": "medium",
      "backgroundColor": "#E5E5EA", "textColor": "#000000",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 20 }
    },
    "destructive": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#FF3B30", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 20 }
    },
    "pill": {
      "fontSize": 14, "fontWeight": "medium",
      "backgroundColor": "#F2F2F7", "textColor": "#000000",
      "cornerRadius": 20, "height": 36, "padding": { "horizontal": 16 }
    },
    "pillSelected": {
      "fontSize": 14, "fontWeight": "semibold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 20, "height": 36, "padding": { "horizontal": 16 }
    },
    "countLabel": { "fontSize": 14, "textColor": "#666666" }
  },
  "actions": {
    "increment": { "type": "setState", "path": "tapCount", "value": { "$expr": "${tapCount} + 1" } }
  },
  "dataSources": {
    "countText": { "type": "binding", "template": "Tapped ${tapCount} times" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "children": [
        { "type": "button", "text": "Primary Button", "styleId": "primary", "actions": { "onTap": "increment" } },
        { "type": "button", "text": "Secondary Button", "styleId": "secondary", "actions": { "onTap": "increment" } },
        { "type": "button", "text": "Destructive", "styleId": "destructive", "actions": { "onTap": "increment" } },
        {
          "type": "hstack", "spacing": 8,
          "children": [
            { "type": "button", "text": "Pill 1", "styleId": "pill" },
            { "type": "button", "text": "Pill 2", "styleId": "pillSelected" },
            { "type": "button", "text": "Pill 3", "styleId": "pill" }
          ]
        },
        { "type": "label", "dataSourceId": "countText", "styleId": "countLabel" }
      ]
    }]
  }
}
"""

// MARK: Text Fields

let textFieldsJSON = """
{
  "id": "textfields-example",
  "version": "1.0",
  "state": { "name": "", "email": "", "bio": "" },
  "styles": {
    "label": { "fontSize": 14, "fontWeight": "medium", "textColor": "#333333" },
    "field": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 12 }
    },
    "preview": { "fontSize": 13, "textColor": "#888888" }
  },
  "dataSources": {
    "namePreview": { "type": "binding", "template": "Name: ${name}" },
    "emailPreview": { "type": "binding", "template": "Email: ${email}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Name", "styleId": "label" },
        { "type": "textfield", "placeholder": "Enter your name", "styleId": "field", "bind": "name" },
        { "type": "label", "text": "Email", "styleId": "label" },
        { "type": "textfield", "placeholder": "Enter your email", "styleId": "field", "bind": "email" },
        { "type": "label", "dataSourceId": "namePreview", "styleId": "preview" },
        { "type": "label", "dataSourceId": "emailPreview", "styleId": "preview" }
      ]
    }]
  }
}
"""

// MARK: Toggles

let togglesJSON = """
{
  "id": "toggles-example",
  "version": "1.0",
  "state": { "notifications": true, "darkMode": false, "autoSave": true },
  "styles": {
    "rowLabel": { "fontSize": 16, "textColor": "#000000" },
    "greenTint": { "tintColor": "#34C759" },
    "purpleTint": { "tintColor": "#AF52DE" },
    "orangeTint": { "tintColor": "#FF9500" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "children": [
        {
          "type": "hstack",
          "children": [
            { "type": "label", "text": "Notifications", "styleId": "rowLabel" },
            { "type": "spacer" },
            { "type": "toggle", "bind": "notifications", "styleId": "greenTint" }
          ]
        },
        {
          "type": "hstack",
          "children": [
            { "type": "label", "text": "Dark Mode", "styleId": "rowLabel" },
            { "type": "spacer" },
            { "type": "toggle", "bind": "darkMode", "styleId": "purpleTint" }
          ]
        },
        {
          "type": "hstack",
          "children": [
            { "type": "label", "text": "Auto Save", "styleId": "rowLabel" },
            { "type": "spacer" },
            { "type": "toggle", "bind": "autoSave", "styleId": "orangeTint" }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Sliders

let slidersJSON = """
{
  "id": "sliders-example",
  "version": "1.0",
  "state": { "volume": 0.5, "brightness": 0.75, "temperature": 72 },
  "styles": {
    "label": { "fontSize": 16, "textColor": "#000000" },
    "value": { "fontSize": 14, "fontWeight": "medium", "textColor": "#007AFF" },
    "blueTint": { "tintColor": "#007AFF" },
    "orangeTint": { "tintColor": "#FF9500" },
    "redTint": { "tintColor": "#FF3B30" }
  },
  "dataSources": {
    "volumeText": { "type": "binding", "template": "${volume}" },
    "brightnessText": { "type": "binding", "template": "${brightness}" },
    "tempText": { "type": "binding", "template": "${temperature}F" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "children": [
        {
          "type": "vstack", "spacing": 8, "alignment": "leading",
          "children": [
            {
              "type": "hstack",
              "children": [
                { "type": "label", "text": "Volume", "styleId": "label" },
                { "type": "spacer" },
                { "type": "label", "dataSourceId": "volumeText", "styleId": "value" }
              ]
            },
            { "type": "slider", "bind": "volume", "styleId": "blueTint" }
          ]
        },
        {
          "type": "vstack", "spacing": 8, "alignment": "leading",
          "children": [
            {
              "type": "hstack",
              "children": [
                { "type": "label", "text": "Brightness", "styleId": "label" },
                { "type": "spacer" },
                { "type": "label", "dataSourceId": "brightnessText", "styleId": "value" }
              ]
            },
            { "type": "slider", "bind": "brightness", "styleId": "orangeTint" }
          ]
        },
        {
          "type": "vstack", "spacing": 8, "alignment": "leading",
          "children": [
            {
              "type": "hstack",
              "children": [
                { "type": "label", "text": "Temperature", "styleId": "label" },
                { "type": "spacer" },
                { "type": "label", "dataSourceId": "tempText", "styleId": "value" }
              ]
            },
            { "type": "slider", "bind": "temperature", "minValue": 60, "maxValue": 90, "styleId": "redTint" }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Images

let imagesJSON = """
{
  "id": "images-example",
  "version": "1.0",
  "styles": {
    "iconDefault": { "width": 48, "height": 48 },
    "iconRed": { "width": 48, "height": 48, "tintColor": "#FF3B30" },
    "iconBlue": { "width": 48, "height": 48, "tintColor": "#007AFF" },
    "iconGreen": { "width": 48, "height": 48, "tintColor": "#34C759" },
    "urlImage": { "width": 200, "height": 150, "cornerRadius": 12 },
    "caption": { "fontSize": 12, "textColor": "#888888", "textAlignment": "center" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        {
          "type": "hstack", "spacing": 24,
          "children": [
            {
              "type": "vstack", "spacing": 4,
              "children": [
                { "type": "image", "image": { "system": "star.fill" }, "styleId": "iconDefault" },
                { "type": "label", "text": "Default", "styleId": "caption" }
              ]
            },
            {
              "type": "vstack", "spacing": 4,
              "children": [
                { "type": "image", "image": { "system": "heart.fill" }, "styleId": "iconRed" },
                { "type": "label", "text": "Red Tint", "styleId": "caption" }
              ]
            },
            {
              "type": "vstack", "spacing": 4,
              "children": [
                { "type": "image", "image": { "system": "bell.fill" }, "styleId": "iconBlue" },
                { "type": "label", "text": "Blue Tint", "styleId": "caption" }
              ]
            },
            {
              "type": "vstack", "spacing": 4,
              "children": [
                { "type": "image", "image": { "system": "checkmark.circle.fill" }, "styleId": "iconGreen" },
                { "type": "label", "text": "Green Tint", "styleId": "caption" }
              ]
            }
          ]
        },
        { "type": "image", "image": { "url": "https://images.pexels.com/photos/1658967/pexels-photo-1658967.jpeg?w=400" }, "styleId": "urlImage" },
        { "type": "label", "text": "URL-loaded image", "styleId": "caption" }
      ]
    }]
  }
}
"""

// MARK: Gradients

let gradientsJSON = """
{
  "id": "gradients-example",
  "version": "1.0",
  "styles": {
    "gradientBox": { "width": 280, "height": 80, "cornerRadius": 12 },
    "gradientLabel": { "fontSize": 14, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "caption": { "fontSize": 12, "textColor": "#888888" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 20,
      "alignment": "center",
      "children": [
        {
          "type": "zstack",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#FF6B6B", "location": 0.0 },
                { "color": "#4ECDC4", "location": 1.0 }
              ],
              "gradientStart": "leading", "gradientEnd": "trailing",
              "styleId": "gradientBox"
            },
            { "type": "label", "text": "Horizontal Gradient", "styleId": "gradientLabel" }
          ]
        },
        {
          "type": "zstack",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#667eea", "location": 0.0 },
                { "color": "#764ba2", "location": 1.0 }
              ],
              "gradientStart": "top", "gradientEnd": "bottom",
              "styleId": "gradientBox"
            },
            { "type": "label", "text": "Vertical Gradient", "styleId": "gradientLabel" }
          ]
        },
        {
          "type": "zstack",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#f093fb", "location": 0.0 },
                { "color": "#f5576c", "location": 0.5 },
                { "color": "#4facfe", "location": 1.0 }
              ],
              "gradientStart": "topLeading", "gradientEnd": "bottomTrailing",
              "styleId": "gradientBox"
            },
            { "type": "label", "text": "Multi-stop Diagonal", "styleId": "gradientLabel" }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: - Layouts (L)

// MARK: VStack & HStack

let vstackHstackJSON = """
{
  "id": "stacks-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#000000" },
    "box": { "width": 60, "height": 60, "backgroundColor": "#007AFF", "cornerRadius": 8 },
    "boxGreen": { "width": 60, "height": 60, "backgroundColor": "#34C759", "cornerRadius": 8 },
    "boxOrange": { "width": 60, "height": 60, "backgroundColor": "#FF9500", "cornerRadius": 8 },
    "boxLabel": { "fontSize": 12, "fontWeight": "medium", "textColor": "#FFFFFF" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "HStack (horizontal)", "styleId": "title" },
        {
          "type": "hstack", "spacing": 12,
          "children": [
            { "type": "zstack", "children": [{ "type": "gradient", "gradientColors": [{"color": "#007AFF", "location": 0}], "styleId": "box" }, { "type": "label", "text": "1", "styleId": "boxLabel" }] },
            { "type": "zstack", "children": [{ "type": "gradient", "gradientColors": [{"color": "#34C759", "location": 0}], "styleId": "boxGreen" }, { "type": "label", "text": "2", "styleId": "boxLabel" }] },
            { "type": "zstack", "children": [{ "type": "gradient", "gradientColors": [{"color": "#FF9500", "location": 0}], "styleId": "boxOrange" }, { "type": "label", "text": "3", "styleId": "boxLabel" }] }
          ]
        },
        { "type": "label", "text": "VStack (vertical)", "styleId": "title" },
        {
          "type": "vstack", "spacing": 8,
          "children": [
            { "type": "zstack", "children": [{ "type": "gradient", "gradientColors": [{"color": "#007AFF", "location": 0}], "styleId": "box" }, { "type": "label", "text": "A", "styleId": "boxLabel" }] },
            { "type": "zstack", "children": [{ "type": "gradient", "gradientColors": [{"color": "#34C759", "location": 0}], "styleId": "boxGreen" }, { "type": "label", "text": "B", "styleId": "boxLabel" }] }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: ZStack

let zstackJSON = """
{
  "id": "zstack-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#000000" },
    "bgGradient": { "width": 200, "height": 120, "cornerRadius": 16 },
    "overlayText": { "fontSize": 20, "fontWeight": "bold", "textColor": "#FFFFFF" },
    "badge": {
      "fontSize": 12, "fontWeight": "bold", "textColor": "#FFFFFF",
      "backgroundColor": "#FF3B30", "cornerRadius": 10,
      "padding": { "horizontal": 8, "vertical": 4 }
    }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Layered content with ZStack", "styleId": "title" },
        {
          "type": "zstack",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#667eea", "location": 0.0 },
                { "color": "#764ba2", "location": 1.0 }
              ],
              "gradientStart": "topLeading", "gradientEnd": "bottomTrailing",
              "styleId": "bgGradient"
            },
            { "type": "label", "text": "Overlay Text", "styleId": "overlayText" }
          ]
        },
        {
          "type": "zstack",
          "alignment": "topTrailing",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#11998e", "location": 0.0 },
                { "color": "#38ef7d", "location": 1.0 }
              ],
              "styleId": "bgGradient"
            },
            { "type": "label", "text": "NEW", "styleId": "badge" }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Section Layout - List

let sectionListJSON = """
{
  "id": "section-list-example",
  "version": "1.0",
  "styles": {
    "header": { "fontSize": 22, "fontWeight": "bold", "textColor": "#000000" },
    "rowTitle": { "fontSize": 16, "textColor": "#000000" },
    "rowSubtitle": { "fontSize": 14, "textColor": "#888888" },
    "iconBlue": { "width": 24, "height": 24, "tintColor": "#007AFF" },
    "iconOrange": { "width": 24, "height": 24, "tintColor": "#FF9500" },
    "iconGreen": { "width": 24, "height": 24, "tintColor": "#34C759" },
    "iconPurple": { "width": 24, "height": 24, "tintColor": "#AF52DE" },
    "iconRed": { "width": 24, "height": 24, "tintColor": "#FF3B30" },
    "iconTeal": { "width": 24, "height": 24, "tintColor": "#5AC8FA" },
    "iconPink": { "width": 24, "height": 24, "tintColor": "#FF2D55" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36 },
    "children": [{
      "type": "sectionLayout",
      "sectionSpacing": 24,
      "sections": [{
        "id": "list-section",
        "layout": {
          "type": "list",
          "itemSpacing": 0,
          "showsDividers": true,
          "contentInsets": { "horizontal": 28 }
        },
        "header": {
          "type": "label", "text": "Settings", "styleId": "header",
          "padding": { "bottom": 12 }
        },
        "children": [
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "person.fill" }, "styleId": "iconBlue" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Account", "styleId": "rowTitle" },
                  { "type": "label", "text": "Manage your profile", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "bell.fill" }, "styleId": "iconOrange" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Notifications", "styleId": "rowTitle" },
                  { "type": "label", "text": "Alerts and sounds", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "lock.fill" }, "styleId": "iconGreen" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Privacy", "styleId": "rowTitle" },
                  { "type": "label", "text": "Data and permissions", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "paintbrush.fill" }, "styleId": "iconPurple" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Appearance", "styleId": "rowTitle" },
                  { "type": "label", "text": "Theme and display", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "icloud.fill" }, "styleId": "iconTeal" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Cloud Sync", "styleId": "rowTitle" },
                  { "type": "label", "text": "Backup and restore", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "heart.fill" }, "styleId": "iconPink" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Favorites", "styleId": "rowTitle" },
                  { "type": "label", "text": "Saved items", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "questionmark.circle.fill" }, "styleId": "iconBlue" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Help & Support", "styleId": "rowTitle" },
                  { "type": "label", "text": "FAQs and contact", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "arrow.right.square.fill" }, "styleId": "iconRed" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Sign Out", "styleId": "rowTitle" },
                  { "type": "label", "text": "Log out of your account", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          }
        ]
      },
      {
        "id": "about-section",
        "layout": {
          "type": "list",
          "itemSpacing": 0,
          "showsDividers": true,
          "contentInsets": { "horizontal": 28 }
        },
        "header": {
          "type": "label", "text": "About", "styleId": "header",
          "padding": { "bottom": 12 }
        },
        "children": [
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "info.circle.fill" }, "styleId": "iconBlue" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Version", "styleId": "rowTitle" },
                  { "type": "label", "text": "1.0.0 (Build 42)", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "doc.text.fill" }, "styleId": "iconGreen" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Terms of Service", "styleId": "rowTitle" },
                  { "type": "label", "text": "Legal agreements", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "hand.raised.fill" }, "styleId": "iconOrange" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Privacy Policy", "styleId": "rowTitle" },
                  { "type": "label", "text": "How we handle your data", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          },
          {
            "type": "hstack", "padding": { "vertical": 14 },
            "children": [
              { "type": "image", "image": { "system": "star.fill" }, "styleId": "iconPurple" },
              {
                "type": "vstack", "spacing": 2, "alignment": "leading", "padding": { "leading": 12 },
                "children": [
                  { "type": "label", "text": "Rate the App", "styleId": "rowTitle" },
                  { "type": "label", "text": "Leave a review", "styleId": "rowSubtitle" }
                ]
              },
              { "type": "spacer" }
            ]
          }
        ]
      }]
    }]
  }
}
"""

// MARK: Section Layout - Grid

let sectionGridJSON = """
{
  "id": "section-grid-example",
  "version": "1.0",
  "styles": {
    "header": { "fontSize": 22, "fontWeight": "bold", "textColor": "#000000" },
    "gridItem": { "height": 100, "backgroundColor": "#F2F2F7", "cornerRadius": 12 },
    "itemIcon": { "width": 32, "height": 32, "tintColor": "#007AFF" },
    "itemLabel": { "fontSize": 12, "fontWeight": "medium", "textColor": "#333333" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36 },
    "children": [{
      "type": "sectionLayout",
      "sections": [{
        "id": "grid-section",
        "layout": {
          "type": "grid",
          "columns": 3,
          "itemSpacing": 12,
          "lineSpacing": 12,
          "contentInsets": { "horizontal": 28 }
        },
        "header": {
          "type": "label", "text": "Categories", "styleId": "header",
          "padding": { "bottom": 12 }
        },
        "children": [
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "photo.fill" }, "styleId": "itemIcon" }, { "type": "label", "text": "Photos", "styleId": "itemLabel" }] },
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "video.fill" }, "styleId": "itemIcon" }, { "type": "label", "text": "Videos", "styleId": "itemLabel" }] },
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "doc.fill" }, "styleId": "itemIcon" }, { "type": "label", "text": "Files", "styleId": "itemLabel" }] },
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "music.note" }, "styleId": "itemIcon" }, { "type": "label", "text": "Music", "styleId": "itemLabel" }] },
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "book.fill" }, "styleId": "itemIcon" }, { "type": "label", "text": "Books", "styleId": "itemLabel" }] },
          { "type": "vstack", "spacing": 8, "styleId": "gridItem", "children": [{ "type": "image", "image": { "system": "gamecontroller.fill" }, "styleId": "itemIcon" }, { "type": "label", "text": "Games", "styleId": "itemLabel" }] }
        ]
      }]
    }]
  }
}
"""

// MARK: Section Layout - Flow

let sectionFlowJSON = """
{
  "id": "section-flow-example",
  "version": "1.0",
  "state": { "selected": [] },
  "styles": {
    "header": { "fontSize": 22, "fontWeight": "bold", "textColor": "#000000" },
    "tag": {
      "fontSize": 14, "fontWeight": "medium",
      "backgroundColor": "#F2F2F7", "textColor": "#333333",
      "cornerRadius": 16, "height": 32, "padding": { "horizontal": 14 }
    },
    "tagSelected": {
      "fontSize": 14, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 16, "height": 32, "padding": { "horizontal": 14 }
    }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36 },
    "children": [{
      "type": "sectionLayout",
      "sections": [{
        "id": "flow-section",
        "layout": {
          "type": "flow",
          "itemSpacing": 8,
          "lineSpacing": 10,
          "contentInsets": { "horizontal": 28 }
        },
        "header": {
          "type": "label", "text": "Select Tags", "styleId": "header",
          "padding": { "bottom": 12 }
        },
        "children": [
          { "type": "button", "text": "Swift", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('Swift')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "Swift" } } },
          { "type": "button", "text": "iOS", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('iOS')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "iOS" } } },
          { "type": "button", "text": "SwiftUI", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('SwiftUI')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "SwiftUI" } } },
          { "type": "button", "text": "UIKit", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('UIKit')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "UIKit" } } },
          { "type": "button", "text": "Combine", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('Combine')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "Combine" } } },
          { "type": "button", "text": "Async/Await", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('Async/Await')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "Async/Await" } } },
          { "type": "button", "text": "Core Data", "styles": { "normal": "tag", "selected": "tagSelected" }, "isSelectedBinding": "${selected.contains('Core Data')}", "actions": { "onTap": { "type": "toggleInArray", "path": "selected", "value": "Core Data" } } }
        ]
      }]
    }]
  }
}
"""

// MARK: Section Layout - Horizontal

let sectionHorizontalJSON = """
{
  "id": "section-horizontal-example",
  "version": "1.0",
  "styles": {
    "header": { "fontSize": 22, "fontWeight": "bold", "textColor": "#000000" },
    "card": { "width": 140, "height": 180, "backgroundColor": "#F2F2F7", "cornerRadius": 12 },
    "cardImage": { "width": 140, "height": 100, "cornerRadius": 12 },
    "cardTitle": { "fontSize": 14, "fontWeight": "semibold", "textColor": "#000000" },
    "cardSubtitle": { "fontSize": 12, "textColor": "#888888" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36 },
    "children": [{
      "type": "sectionLayout",
      "sections": [{
        "id": "horizontal-section",
        "layout": {
          "type": "horizontal",
          "itemSpacing": 12,
          "contentInsets": { "leading": 28, "trailing": 28 },
          "showsIndicators": false
        },
        "header": {
          "type": "label", "text": "Featured", "styleId": "header",
          "padding": { "bottom": 12 }
        },
        "children": [
          { "type": "vstack", "spacing": 8, "alignment": "leading", "styleId": "card", "children": [{ "type": "gradient", "gradientColors": [{"color": "#FF6B6B", "location": 0}, {"color": "#4ECDC4", "location": 1}], "styleId": "cardImage" }, { "type": "label", "text": "Card One", "styleId": "cardTitle", "padding": { "horizontal": 8 } }, { "type": "label", "text": "Description", "styleId": "cardSubtitle", "padding": { "horizontal": 8 } }] },
          { "type": "vstack", "spacing": 8, "alignment": "leading", "styleId": "card", "children": [{ "type": "gradient", "gradientColors": [{"color": "#667eea", "location": 0}, {"color": "#764ba2", "location": 1}], "styleId": "cardImage" }, { "type": "label", "text": "Card Two", "styleId": "cardTitle", "padding": { "horizontal": 8 } }, { "type": "label", "text": "Description", "styleId": "cardSubtitle", "padding": { "horizontal": 8 } }] },
          { "type": "vstack", "spacing": 8, "alignment": "leading", "styleId": "card", "children": [{ "type": "gradient", "gradientColors": [{"color": "#f093fb", "location": 0}, {"color": "#f5576c", "location": 1}], "styleId": "cardImage" }, { "type": "label", "text": "Card Three", "styleId": "cardTitle", "padding": { "horizontal": 8 } }, { "type": "label", "text": "Description", "styleId": "cardSubtitle", "padding": { "horizontal": 8 } }] },
          { "type": "vstack", "spacing": 8, "alignment": "leading", "styleId": "card", "children": [{ "type": "gradient", "gradientColors": [{"color": "#11998e", "location": 0}, {"color": "#38ef7d", "location": 1}], "styleId": "cardImage" }, { "type": "label", "text": "Card Four", "styleId": "cardTitle", "padding": { "horizontal": 8 } }, { "type": "label", "text": "Description", "styleId": "cardSubtitle", "padding": { "horizontal": 8 } }] }
        ]
      }]
    }]
  }
}
"""

// MARK: - Actions (A)

// MARK: Set State

let setStateJSON = """
{
  "id": "setstate-example",
  "version": "1.0",
  "state": { "count": 0, "message": "Hello" },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "value": { "fontSize": 48, "fontWeight": "bold", "textColor": "#007AFF" },
    "button": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 20 }
    }
  },
  "actions": {
    "increment": { "type": "setState", "path": "count", "value": { "$expr": "${count} + 1" } },
    "decrement": { "type": "setState", "path": "count", "value": { "$expr": "${count} - 1" } },
    "reset": { "type": "setState", "path": "count", "value": 0 }
  },
  "dataSources": {
    "countDisplay": { "type": "binding", "template": "${count}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Counter with setState", "styleId": "title" },
        { "type": "label", "dataSourceId": "countDisplay", "styleId": "value" },
        {
          "type": "hstack", "spacing": 12,
          "children": [
            { "type": "button", "text": "-", "styleId": "button", "actions": { "onTap": "decrement" } },
            { "type": "button", "text": "Reset", "styleId": "button", "actions": { "onTap": "reset" } },
            { "type": "button", "text": "+", "styleId": "button", "actions": { "onTap": "increment" } }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Toggle State

let toggleStateJSON = """
{
  "id": "togglestate-example",
  "version": "1.0",
  "state": { "isOn": false },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "status": { "fontSize": 24, "fontWeight": "semibold" },
    "buttonOff": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#8E8E93", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 24 }
    },
    "buttonOn": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 24 }
    }
  },
  "actions": {
    "toggle": { "type": "toggleState", "path": "isOn" }
  },
  "dataSources": {
    "statusText": { "type": "binding", "template": "${isOn ? 'ON' : 'OFF'}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Toggle State Action", "styleId": "title" },
        { "type": "label", "dataSourceId": "statusText", "styleId": "status" },
        {
          "type": "button",
          "text": "Toggle",
          "styles": { "normal": "buttonOff", "selected": "buttonOn" },
          "isSelectedBinding": "isOn",
          "actions": { "onTap": "toggle" }
        }
      ]
    }]
  }
}
"""

// MARK: Show Alert

let showAlertJSON = """
{
  "id": "showalert-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 14, "textColor": "#666666" },
    "button": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 24 }
    },
    "destructiveButton": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#FF3B30", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 24 }
    }
  },
  "actions": {
    "simpleAlert": {
      "type": "showAlert",
      "title": "Hello!",
      "message": "This is a simple alert.",
      "buttons": [{ "label": "OK", "style": "default" }]
    },
    "confirmAlert": {
      "type": "showAlert",
      "title": "Confirm Action",
      "message": "Are you sure you want to proceed?",
      "buttons": [
        { "label": "Cancel", "style": "cancel" },
        { "label": "Confirm", "style": "default" }
      ]
    },
    "destructiveAlert": {
      "type": "showAlert",
      "title": "Delete Item?",
      "message": "This action cannot be undone.",
      "buttons": [
        { "label": "Cancel", "style": "cancel" },
        { "label": "Delete", "style": "destructive" }
      ]
    }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Alert Examples", "styleId": "title" },
        { "type": "label", "text": "Tap buttons to show different alerts", "styleId": "subtitle" },
        { "type": "button", "text": "Simple Alert", "styleId": "button", "actions": { "onTap": "simpleAlert" } },
        { "type": "button", "text": "Confirmation Alert", "styleId": "button", "actions": { "onTap": "confirmAlert" } },
        { "type": "button", "text": "Destructive Alert", "styleId": "destructiveButton", "actions": { "onTap": "destructiveAlert" } }
      ]
    }]
  }
}
"""

// MARK: Dismiss

let dismissJSON = """
{
  "id": "dismiss-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 24, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 16, "textColor": "#666666" },
    "button": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 50, "padding": { "horizontal": 32 }
    },
    "successIcon": { "width": 80, "height": 80, "tintColor": "#34C759" }
  },
  "actions": {
    "close": { "type": "dismiss" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        { "type": "spacer" },
        { "type": "image", "image": { "system": "checkmark.circle.fill" }, "styleId": "successIcon" },
        { "type": "label", "text": "Success!", "styleId": "title" },
        { "type": "label", "text": "Tap the button to dismiss this view", "styleId": "subtitle" },
        { "type": "spacer" },
        { "type": "button", "text": "Done", "styleId": "button", "fillWidth": true, "actions": { "onTap": "close" } }
      ]
    }]
  }
}
"""

// MARK: Navigate

let navigateJSON = """
{
  "id": "navigate-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "subtitle": { "fontSize": 14, "textColor": "#666666" },
    "row": { "padding": { "vertical": 16 } },
    "rowTitle": { "fontSize": 16, "textColor": "#000000" },
    "rowIcon": { "width": 24, "height": 24, "tintColor": "#007AFF" },
    "chevron": { "width": 16, "height": 16, "tintColor": "#C7C7CC" }
  },
  "actions": {
    "goToProfile": { "type": "navigate", "destination": "profile" },
    "goToSettings": { "type": "navigate", "destination": "settings" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Navigation Actions", "styleId": "title" },
        { "type": "label", "text": "Navigate action pushes a new destination", "styleId": "subtitle" },
        {
          "type": "button", "styleId": "row",
          "actions": { "onTap": "goToProfile" },
          "children": [{
            "type": "hstack",
            "children": [
              { "type": "image", "image": { "system": "person.circle" }, "styleId": "rowIcon" },
              { "type": "label", "text": "Go to Profile", "styleId": "rowTitle", "padding": { "leading": 12 } },
              { "type": "spacer" },
              { "type": "image", "image": { "system": "chevron.right" }, "styleId": "chevron" }
            ]
          }]
        },
        {
          "type": "button", "styleId": "row",
          "actions": { "onTap": "goToSettings" },
          "children": [{
            "type": "hstack",
            "children": [
              { "type": "image", "image": { "system": "gear" }, "styleId": "rowIcon" },
              { "type": "label", "text": "Go to Settings", "styleId": "rowTitle", "padding": { "leading": 12 } },
              { "type": "spacer" },
              { "type": "image", "image": { "system": "chevron.right" }, "styleId": "chevron" }
            ]
          }]
        }
      ]
    }]
  }
}
"""

// MARK: Sequence

let sequenceJSON = """
{
  "id": "sequence-example",
  "version": "1.0",
  "state": { "step": 0 },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "stepLabel": { "fontSize": 48, "fontWeight": "bold", "textColor": "#007AFF" },
    "button": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 24 }
    }
  },
  "actions": {
    "multiStep": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "step", "value": { "$expr": "${step} + 1" } },
        {
          "type": "showAlert",
          "title": "Step Complete",
          "message": { "type": "binding", "template": "You are now on step ${step}" },
          "buttons": [{ "label": "OK", "style": "default" }]
        }
      ]
    }
  },
  "dataSources": {
    "stepText": { "type": "binding", "template": "Step ${step}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Sequence Actions", "styleId": "title" },
        { "type": "label", "dataSourceId": "stepText", "styleId": "stepLabel" },
        { "type": "button", "text": "Next Step", "styleId": "button", "actions": { "onTap": "multiStep" } }
      ]
    }]
  }
}
"""

// MARK: Array Actions

let arrayActionsJSON = """
{
  "id": "arrayactions-example",
  "version": "1.0",
  "state": { "items": ["Apple", "Banana"], "newItem": "" },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "count": { "fontSize": 14, "textColor": "#666666" },
    "field": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 12 }
    },
    "addButton": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 8, "height": 44, "padding": { "horizontal": 16 }
    },
    "removeButton": {
      "fontSize": 14, "fontWeight": "medium",
      "backgroundColor": "#FF3B30", "textColor": "#FFFFFF",
      "cornerRadius": 6, "padding": { "horizontal": 10, "vertical": 6 }
    },
    "itemLabel": { "fontSize": 16, "textColor": "#000000" }
  },
  "actions": {
    "addItem": {
      "type": "sequence",
      "steps": [
        { "type": "appendToArray", "path": "items", "value": { "$expr": "${newItem}" } },
        { "type": "setState", "path": "newItem", "value": "" }
      ]
    }
  },
  "dataSources": {
    "countText": { "type": "binding", "template": "${items.count} items" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Array Actions", "styleId": "title" },
        { "type": "label", "dataSourceId": "countText", "styleId": "count" },
        {
          "type": "hstack", "spacing": 8,
          "children": [
            { "type": "textfield", "placeholder": "New item", "styleId": "field", "bind": "newItem" },
            { "type": "button", "text": "Add", "styleId": "addButton", "actions": { "onTap": "addItem" } }
          ]
        },
        { "type": "label", "text": "Add items above and watch the count update!", "styleId": "count" }
      ]
    }]
  }
}
"""

// MARK: - Data (D)

// MARK: Static Data

let staticDataJSON = """
{
  "id": "staticdata-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "label": { "fontSize": 14, "fontWeight": "medium", "textColor": "#888888" },
    "value": { "fontSize": 16, "textColor": "#000000" }
  },
  "dataSources": {
    "appName": { "type": "static", "value": "CLADS Renderer" },
    "version": { "type": "static", "value": "1.0.0" },
    "author": { "type": "static", "value": "Your Name" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 20,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Static Data Sources", "styleId": "title" },
        {
          "type": "vstack", "spacing": 4, "alignment": "leading",
          "children": [
            { "type": "label", "text": "App Name", "styleId": "label" },
            { "type": "label", "dataSourceId": "appName", "styleId": "value" }
          ]
        },
        {
          "type": "vstack", "spacing": 4, "alignment": "leading",
          "children": [
            { "type": "label", "text": "Version", "styleId": "label" },
            { "type": "label", "dataSourceId": "version", "styleId": "value" }
          ]
        },
        {
          "type": "vstack", "spacing": 4, "alignment": "leading",
          "children": [
            { "type": "label", "text": "Author", "styleId": "label" },
            { "type": "label", "dataSourceId": "author", "styleId": "value" }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Binding Data

let bindingDataJSON = """
{
  "id": "bindingdata-example",
  "version": "1.0",
  "state": { "username": "JohnDoe", "email": "john@example.com" },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "label": { "fontSize": 14, "fontWeight": "medium", "textColor": "#888888" },
    "field": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 12 }
    },
    "preview": { "fontSize": 14, "textColor": "#007AFF" }
  },
  "dataSources": {
    "usernamePreview": { "type": "binding", "template": "Username: ${username}" },
    "emailPreview": { "type": "binding", "template": "Email: ${email}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Two-Way Binding", "styleId": "title" },
        { "type": "label", "text": "Username", "styleId": "label" },
        { "type": "textfield", "styleId": "field", "bind": "username" },
        { "type": "label", "text": "Email", "styleId": "label" },
        { "type": "textfield", "styleId": "field", "bind": "email" },
        { "type": "label", "dataSourceId": "usernamePreview", "styleId": "preview" },
        { "type": "label", "dataSourceId": "emailPreview", "styleId": "preview" }
      ]
    }]
  }
}
"""

// MARK: Expression Data

let expressionDataJSON = """
{
  "id": "expressiondata-example",
  "version": "1.0",
  "state": { "price": 100, "quantity": 2, "discount": 10 },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "label": { "fontSize": 14, "textColor": "#666666" },
    "value": { "fontSize": 20, "fontWeight": "semibold", "textColor": "#007AFF" },
    "slider": { "tintColor": "#007AFF" }
  },
  "dataSources": {
    "priceText": { "type": "binding", "template": "Price: $${price}" },
    "quantityText": { "type": "binding", "template": "Quantity: ${quantity}" },
    "discountText": { "type": "binding", "template": "Discount: ${discount}%" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 20,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Expression Evaluation", "styleId": "title" },
        { "type": "label", "dataSourceId": "priceText", "styleId": "label" },
        { "type": "slider", "bind": "price", "minValue": 0, "maxValue": 200, "styleId": "slider" },
        { "type": "label", "dataSourceId": "quantityText", "styleId": "label" },
        { "type": "slider", "bind": "quantity", "minValue": 1, "maxValue": 10, "styleId": "slider" },
        { "type": "label", "dataSourceId": "discountText", "styleId": "label" },
        { "type": "slider", "bind": "discount", "minValue": 0, "maxValue": 50, "styleId": "slider" }
      ]
    }]
  }
}
"""

// MARK: State Interpolation

let stateInterpolationJSON = """
{
  "id": "interpolation-example",
  "version": "1.0",
  "state": { "firstName": "John", "lastName": "Doe", "age": 25 },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "label": { "fontSize": 14, "textColor": "#888888" },
    "field": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 8,
      "padding": { "horizontal": 12, "vertical": 12 }
    },
    "result": {
      "fontSize": 16, "textColor": "#FFFFFF",
      "backgroundColor": "#007AFF", "cornerRadius": 8,
      "padding": { "all": 16 }
    }
  },
  "dataSources": {
    "greeting": { "type": "binding", "template": "Hello, ${firstName} ${lastName}! You are ${age} years old." }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Template Interpolation", "styleId": "title" },
        { "type": "label", "text": "First Name", "styleId": "label" },
        { "type": "textfield", "styleId": "field", "bind": "firstName" },
        { "type": "label", "text": "Last Name", "styleId": "label" },
        { "type": "textfield", "styleId": "field", "bind": "lastName" },
        { "type": "label", "text": "Age", "styleId": "label" },
        { "type": "slider", "bind": "age", "minValue": 0, "maxValue": 100 },
        { "type": "label", "dataSourceId": "greeting", "styleId": "result" }
      ]
    }]
  }
}
"""

// MARK: - Styles (S)

// MARK: Basic Styles

let basicStylesJSON = """
{
  "id": "basicstyles-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "large": { "fontSize": 24, "fontWeight": "bold", "textColor": "#000000" },
    "medium": { "fontSize": 16, "fontWeight": "regular", "textColor": "#333333" },
    "small": { "fontSize": 12, "fontWeight": "light", "textColor": "#888888" },
    "colored": { "fontSize": 16, "textColor": "#007AFF" },
    "background": {
      "fontSize": 16, "textColor": "#FFFFFF",
      "backgroundColor": "#FF3B30", "cornerRadius": 8,
      "padding": { "horizontal": 16, "vertical": 8 }
    },
    "rounded": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 20,
      "padding": { "horizontal": 20, "vertical": 10 }
    }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "alignment": "leading",
      "children": [
        { "type": "label", "text": "Basic Style Properties", "styleId": "title" },
        { "type": "label", "text": "Large Bold Text", "styleId": "large" },
        { "type": "label", "text": "Medium Regular Text", "styleId": "medium" },
        { "type": "label", "text": "Small Light Text", "styleId": "small" },
        { "type": "label", "text": "Colored Text", "styleId": "colored" },
        { "type": "label", "text": "Background + Corner Radius", "styleId": "background" },
        { "type": "label", "text": "Pill Shape", "styleId": "rounded" }
      ]
    }]
  }
}
"""

// MARK: Style Inheritance

let styleInheritanceJSON = """
{
  "id": "styleinheritance-example",
  "version": "1.0",
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "baseButton": {
      "fontSize": 16, "fontWeight": "semibold",
      "cornerRadius": 10, "height": 44,
      "padding": { "horizontal": 20 }
    },
    "primaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF"
    },
    "secondaryButton": {
      "inherits": "baseButton",
      "backgroundColor": "#E5E5EA", "textColor": "#000000"
    },
    "dangerButton": {
      "inherits": "baseButton",
      "backgroundColor": "#FF3B30", "textColor": "#FFFFFF"
    },
    "successButton": {
      "inherits": "baseButton",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF"
    },
    "note": { "fontSize": 12, "textColor": "#888888", "textAlignment": "center" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 16,
      "children": [
        { "type": "label", "text": "Style Inheritance", "styleId": "title" },
        { "type": "label", "text": "All buttons inherit from baseButton", "styleId": "note" },
        { "type": "button", "text": "Primary Button", "styleId": "primaryButton" },
        { "type": "button", "text": "Secondary Button", "styleId": "secondaryButton" },
        { "type": "button", "text": "Danger Button", "styleId": "dangerButton" },
        { "type": "button", "text": "Success Button", "styleId": "successButton" }
      ]
    }]
  }
}
"""

// MARK: Conditional Styles

let conditionalStylesJSON = """
{
  "id": "conditionalstyles-example",
  "version": "1.0",
  "state": { "isActive": false },
  "styles": {
    "title": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "normalCard": {
      "backgroundColor": "#F2F2F7", "cornerRadius": 12,
      "padding": { "all": 20 }
    },
    "activeCard": {
      "backgroundColor": "#007AFF", "cornerRadius": 12,
      "padding": { "all": 20 }
    },
    "normalText": { "fontSize": 16, "textColor": "#333333" },
    "activeText": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "toggleButton": {
      "fontSize": 16, "fontWeight": "medium",
      "backgroundColor": "#E5E5EA", "textColor": "#000000",
      "cornerRadius": 8, "height": 40, "padding": { "horizontal": 16 }
    },
    "toggleButtonSelected": {
      "fontSize": 16, "fontWeight": "semibold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 8, "height": 40, "padding": { "horizontal": 16 }
    }
  },
  "actions": {
    "toggle": { "type": "toggleState", "path": "isActive" }
  },
  "dataSources": {
    "statusText": { "type": "binding", "template": "${isActive ? 'Card is ACTIVE' : 'Card is inactive'}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 36, "leading": 28, "trailing": 28 },
    "children": [{
      "type": "vstack",
      "spacing": 20,
      "alignment": "center",
      "children": [
        { "type": "label", "text": "Conditional Styles", "styleId": "title" },
        {
          "type": "button",
          "text": "Toggle State",
          "styles": { "normal": "toggleButton", "selected": "toggleButtonSelected" },
          "isSelectedBinding": "isActive",
          "actions": { "onTap": "toggle" }
        },
        { "type": "label", "dataSourceId": "statusText", "styleId": "normalText" }
      ]
    }]
  }
}
"""

// MARK: - Complex Examples (Combining CLADS Elements)

// MARK: Shopping Cart

let shoppingCartJSON = """
{
  "id": "shopping-cart",
  "version": "1.0",
  "state": {
    "cartItems": [
      { "name": "Wireless Headphones", "price": 199.99, "quantity": 1, "image": "headphones" },
      { "name": "Smart Watch", "price": 299.99, "quantity": 1, "image": "applewatch" },
      { "name": "Phone Case", "price": 29.99, "quantity": 2, "image": "iphone" }
    ],
    "promoCode": "",
    "promoApplied": false
  },
  "styles": {
    "screenTitle": { "fontSize": 28, "fontWeight": "bold", "textColor": "#000000" },
    "itemCount": { "fontSize": 14, "textColor": "#8E8E93" },
    "sectionHeader": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#000000" },
    "productImage": { "width": 80, "height": 80, "backgroundColor": "#F2F2F7", "cornerRadius": 12 },
    "productIcon": { "width": 40, "height": 40, "tintColor": "#007AFF" },
    "productName": { "fontSize": 16, "fontWeight": "medium", "textColor": "#000000" },
    "productPrice": { "fontSize": 14, "fontWeight": "semibold", "textColor": "#007AFF" },
    "quantityLabel": { "fontSize": 14, "textColor": "#8E8E93" },
    "quantityValue": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#000000" },
    "quantityButton": {
      "fontSize": 18, "fontWeight": "bold",
      "backgroundColor": "#F2F2F7", "textColor": "#007AFF",
      "cornerRadius": 8, "width": 32, "height": 32
    },
    "removeButton": { "fontSize": 14, "textColor": "#FF3B30" },
    "promoField": {
      "fontSize": 16, "textColor": "#000000",
      "backgroundColor": "#F2F2F7", "cornerRadius": 10,
      "padding": { "horizontal": 14, "vertical": 12 }
    },
    "applyButton": {
      "fontSize": 14, "fontWeight": "semibold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 16 }
    },
    "summaryRow": { "fontSize": 16, "textColor": "#000000" },
    "summaryLabel": { "fontSize": 16, "textColor": "#8E8E93" },
    "totalLabel": { "fontSize": 18, "fontWeight": "bold", "textColor": "#000000" },
    "totalValue": { "fontSize": 24, "fontWeight": "bold", "textColor": "#007AFF" },
    "checkoutButton": {
      "fontSize": 18, "fontWeight": "semibold",
      "backgroundColor": "#007AFF", "textColor": "#FFFFFF",
      "cornerRadius": 14, "height": 56
    },
    "emptyCartIcon": { "width": 80, "height": 80, "tintColor": "#C7C7CC" },
    "emptyCartText": { "fontSize": 18, "fontWeight": "medium", "textColor": "#8E8E93" },
    "continueButton": {
      "fontSize": 16, "fontWeight": "medium",
      "backgroundColor": "#E5E5EA", "textColor": "#007AFF",
      "cornerRadius": 10, "height": 44, "padding": { "horizontal": 20 }
    },
    "divider": { "height": 1, "backgroundColor": "#E5E5EA" },
    "cardBackground": {
      "backgroundColor": "#FFFFFF", "cornerRadius": 16,
      "padding": { "all": 16 }
    },
    "summaryCard": {
      "backgroundColor": "#F8F8F8", "cornerRadius": 16,
      "padding": { "all": 20 }
    },
    "closeButton": { "width": 28, "height": 28, "tintColor": "#8E8E93" }
  },
  "actions": {
    "close": { "type": "dismiss" },
    "applyPromo": {
      "type": "sequence",
      "steps": [
        { "type": "setState", "path": "promoApplied", "value": true },
        {
          "type": "showAlert",
          "title": "Promo Applied!",
          "message": "You saved 10% on your order",
          "buttons": [{ "label": "Awesome!", "style": "default" }]
        }
      ]
    },
    "checkout": {
      "type": "showAlert",
      "title": "Proceed to Checkout?",
      "message": "You will be redirected to payment",
      "buttons": [
        { "label": "Cancel", "style": "cancel" },
        { "label": "Continue", "style": "default" }
      ]
    },
    "removeItem": {
      "type": "showAlert",
      "title": "Remove Item?",
      "message": "Are you sure you want to remove this item?",
      "buttons": [
        { "label": "Cancel", "style": "cancel" },
        { "label": "Remove", "style": "destructive" }
      ]
    }
  },
  "dataSources": {
    "itemCountText": { "type": "binding", "template": "${cartItems.count} items in cart" },
    "subtotal": { "type": "static", "value": "$559.96" },
    "shipping": { "type": "static", "value": "FREE" },
    "tax": { "type": "static", "value": "$44.80" },
    "total": { "type": "static", "value": "$604.76" }
  },
  "root": {
    "backgroundColor": "#F2F2F7",
    "edgeInsets": { "top": 20 },
    "children": [{
      "type": "sectionLayout",
      "sectionSpacing": 16,
      "sections": [
        {
          "id": "header",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "children": [
            {
              "type": "hstack",
              "children": [
                {
                  "type": "vstack", "alignment": "leading", "spacing": 4,
                  "children": [
                    { "type": "label", "text": "Shopping Cart", "styleId": "screenTitle" },
                    { "type": "label", "dataSourceId": "itemCountText", "styleId": "itemCount" }
                  ]
                },
                { "type": "spacer" },
                {
                  "type": "button",
                  "actions": { "onTap": "close" },
                  "children": [{ "type": "image", "image": { "system": "xmark.circle.fill" }, "styleId": "closeButton" }]
                }
              ]
            }
          ]
        },
        {
          "id": "items",
          "layout": { "type": "list", "showsDividers": false, "itemSpacing": 12, "contentInsets": { "horizontal": 20 } },
          "children": [
            {
              "type": "hstack", "spacing": 16, "styleId": "cardBackground",
              "children": [
                {
                  "type": "zstack", "styleId": "productImage",
                  "children": [
                    { "type": "image", "image": { "system": "headphones" }, "styleId": "productIcon" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 6, "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "Wireless Headphones", "styleId": "productName" },
                    { "type": "label", "text": "$199.99", "styleId": "productPrice" },
                    {
                      "type": "hstack", "spacing": 12,
                      "children": [
                        { "type": "button", "text": "-", "styleId": "quantityButton" },
                        { "type": "label", "text": "1", "styleId": "quantityValue" },
                        { "type": "button", "text": "+", "styleId": "quantityButton" }
                      ]
                    }
                  ]
                },
                { "type": "spacer" },
                { "type": "button", "text": "Remove", "styleId": "removeButton", "actions": { "onTap": "removeItem" } }
              ]
            },
            {
              "type": "hstack", "spacing": 16, "styleId": "cardBackground",
              "children": [
                {
                  "type": "zstack", "styleId": "productImage",
                  "children": [
                    { "type": "image", "image": { "system": "applewatch" }, "styleId": "productIcon" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 6, "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "Smart Watch", "styleId": "productName" },
                    { "type": "label", "text": "$299.99", "styleId": "productPrice" },
                    {
                      "type": "hstack", "spacing": 12,
                      "children": [
                        { "type": "button", "text": "-", "styleId": "quantityButton" },
                        { "type": "label", "text": "1", "styleId": "quantityValue" },
                        { "type": "button", "text": "+", "styleId": "quantityButton" }
                      ]
                    }
                  ]
                },
                { "type": "spacer" },
                { "type": "button", "text": "Remove", "styleId": "removeButton", "actions": { "onTap": "removeItem" } }
              ]
            },
            {
              "type": "hstack", "spacing": 16, "styleId": "cardBackground",
              "children": [
                {
                  "type": "zstack", "styleId": "productImage",
                  "children": [
                    { "type": "image", "image": { "system": "iphone" }, "styleId": "productIcon" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 6, "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "Phone Case", "styleId": "productName" },
                    { "type": "label", "text": "$29.99", "styleId": "productPrice" },
                    {
                      "type": "hstack", "spacing": 12,
                      "children": [
                        { "type": "button", "text": "-", "styleId": "quantityButton" },
                        { "type": "label", "text": "2", "styleId": "quantityValue" },
                        { "type": "button", "text": "+", "styleId": "quantityButton" }
                      ]
                    }
                  ]
                },
                { "type": "spacer" },
                { "type": "button", "text": "Remove", "styleId": "removeButton", "actions": { "onTap": "removeItem" } }
              ]
            }
          ]
        },
        {
          "id": "promo",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
          "children": [
            {
              "type": "vstack", "spacing": 12, "styleId": "cardBackground",
              "children": [
                { "type": "label", "text": "Promo Code", "styleId": "sectionHeader" },
                {
                  "type": "hstack", "spacing": 12,
                  "children": [
                    { "type": "textfield", "placeholder": "Enter code", "styleId": "promoField", "bind": "promoCode" },
                    { "type": "button", "text": "Apply", "styleId": "applyButton", "actions": { "onTap": "applyPromo" } }
                  ]
                }
              ]
            }
          ]
        },
        {
          "id": "summary",
          "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20, "bottom": 20 } },
          "children": [
            {
              "type": "vstack", "spacing": 16, "styleId": "summaryCard",
              "children": [
                { "type": "label", "text": "Order Summary", "styleId": "sectionHeader" },
                {
                  "type": "hstack",
                  "children": [
                    { "type": "label", "text": "Subtotal", "styleId": "summaryLabel" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "subtotal", "styleId": "summaryRow" }
                  ]
                },
                {
                  "type": "hstack",
                  "children": [
                    { "type": "label", "text": "Shipping", "styleId": "summaryLabel" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "shipping", "styleId": "summaryRow" }
                  ]
                },
                {
                  "type": "hstack",
                  "children": [
                    { "type": "label", "text": "Tax", "styleId": "summaryLabel" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "tax", "styleId": "summaryRow" }
                  ]
                },
                { "type": "gradient", "gradientColors": [{"color": "#E5E5EA", "location": 0}], "styleId": "divider" },
                {
                  "type": "hstack",
                  "children": [
                    { "type": "label", "text": "Total", "styleId": "totalLabel" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "total", "styleId": "totalValue" }
                  ]
                },
                { "type": "button", "text": "Proceed to Checkout", "styleId": "checkoutButton", "fillWidth": true, "actions": { "onTap": "checkout" } }
              ]
            }
          ]
        }
      ]
    }]
  }
}
"""

// MARK: Music Player

let musicPlayerJSON = """
{
  "id": "music-player",
  "version": "1.0",
  "state": {
    "isPlaying": false,
    "currentTime": 127,
    "duration": 245,
    "volume": 0.75,
    "isShuffled": false,
    "repeatMode": "off",
    "isFavorite": false,
    "showQueue": false
  },
  "styles": {
    "albumArt": { "width": 280, "height": 280, "cornerRadius": 20 },
    "albumGradient": {
      "width": 280, "height": 280, "cornerRadius": 20
    },
    "albumIcon": { "width": 80, "height": 80, "tintColor": "#FFFFFF" },
    "songTitle": { "fontSize": 24, "fontWeight": "bold", "textColor": "#000000", "textAlignment": "center" },
    "artistName": { "fontSize": 18, "textColor": "#8E8E93", "textAlignment": "center" },
    "timeLabel": { "fontSize": 12, "fontWeight": "medium", "textColor": "#8E8E93" },
    "progressBar": { "tintColor": "#007AFF", "height": 4 },
    "controlIcon": { "width": 28, "height": 28, "tintColor": "#000000" },
    "controlIconActive": { "width": 28, "height": 28, "tintColor": "#007AFF" },
    "playButton": {
      "width": 72, "height": 72,
      "backgroundColor": "#007AFF", "cornerRadius": 36
    },
    "playIcon": { "width": 32, "height": 32, "tintColor": "#FFFFFF" },
    "skipIcon": { "width": 36, "height": 36, "tintColor": "#000000" },
    "volumeIcon": { "width": 20, "height": 20, "tintColor": "#8E8E93" },
    "volumeSlider": { "tintColor": "#007AFF" },
    "queueButton": {
      "fontSize": 14, "fontWeight": "medium",
      "backgroundColor": "#F2F2F7", "textColor": "#007AFF",
      "cornerRadius": 8, "height": 36, "padding": { "horizontal": 16 }
    },
    "shuffleButton": {
      "width": 44, "height": 44,
      "backgroundColor": "#F2F2F7", "cornerRadius": 22
    },
    "shuffleButtonActive": {
      "width": 44, "height": 44,
      "backgroundColor": "#007AFF", "cornerRadius": 22
    },
    "shuffleIcon": { "width": 20, "height": 20, "tintColor": "#8E8E93" },
    "shuffleIconActive": { "width": 20, "height": 20, "tintColor": "#FFFFFF" },
    "heartIcon": { "width": 24, "height": 24, "tintColor": "#C7C7CC" },
    "heartIconFilled": { "width": 24, "height": 24, "tintColor": "#FF3B30" },
    "queueItem": { "padding": { "vertical": 10 } },
    "queueTitle": { "fontSize": 16, "textColor": "#000000" },
    "queueArtist": { "fontSize": 14, "textColor": "#8E8E93" },
    "queueImage": { "width": 48, "height": 48, "cornerRadius": 8, "backgroundColor": "#F2F2F7" },
    "queueIcon": { "width": 24, "height": 24, "tintColor": "#007AFF" },
    "nowPlayingBadge": {
      "fontSize": 10, "fontWeight": "bold",
      "backgroundColor": "#34C759", "textColor": "#FFFFFF",
      "cornerRadius": 4, "padding": { "horizontal": 6, "vertical": 2 }
    },
    "closeButton": { "width": 28, "height": 28, "tintColor": "#8E8E93" }
  },
  "actions": {
    "close": { "type": "dismiss" },
    "togglePlay": { "type": "toggleState", "path": "isPlaying" },
    "toggleShuffle": { "type": "toggleState", "path": "isShuffled" },
    "toggleFavorite": { "type": "toggleState", "path": "isFavorite" },
    "toggleQueue": { "type": "toggleState", "path": "showQueue" },
    "skipNext": {
      "type": "showAlert",
      "title": "Next Track",
      "message": "Skipping to next song...",
      "buttons": [{ "label": "OK", "style": "default" }]
    },
    "skipPrevious": {
      "type": "showAlert",
      "title": "Previous Track",
      "message": "Going to previous song...",
      "buttons": [{ "label": "OK", "style": "default" }]
    }
  },
  "dataSources": {
    "currentTimeText": { "type": "binding", "template": "2:07" },
    "durationText": { "type": "binding", "template": "4:05" },
    "playButtonIcon": { "type": "binding", "template": "${isPlaying ? 'pause.fill' : 'play.fill'}" }
  },
  "root": {
    "backgroundColor": "#FFFFFF",
    "edgeInsets": { "top": 20 },
    "children": [{
      "type": "vstack",
      "spacing": 24,
      "alignment": "center",
      "padding": { "horizontal": 32 },
      "children": [
        {
          "type": "hstack", "padding": { "bottom": 8 },
          "children": [
            { "type": "spacer" },
            {
              "type": "button",
              "actions": { "onTap": "close" },
              "children": [{ "type": "image", "image": { "system": "xmark.circle.fill" }, "styleId": "closeButton" }]
            }
          ]
        },
        {
          "type": "zstack", "styleId": "albumArt",
          "children": [
            {
              "type": "gradient",
              "gradientColors": [
                { "color": "#667eea", "location": 0.0 },
                { "color": "#764ba2", "location": 0.5 },
                { "color": "#f093fb", "location": 1.0 }
              ],
              "gradientStart": "topLeading", "gradientEnd": "bottomTrailing",
              "styleId": "albumGradient"
            },
            { "type": "image", "image": { "system": "music.note" }, "styleId": "albumIcon" }
          ]
        },
        {
          "type": "hstack",
          "children": [
            {
              "type": "button",
              "actions": { "onTap": "toggleFavorite" },
              "children": [{
                "type": "image",
                "image": { "system": "heart.fill" },
                "styles": { "normal": "heartIcon", "selected": "heartIconFilled" },
                "isSelectedBinding": "isFavorite"
              }]
            },
            { "type": "spacer" },
            {
              "type": "vstack", "spacing": 4, "alignment": "center",
              "children": [
                { "type": "label", "text": "Midnight Dreams", "styleId": "songTitle" },
                { "type": "label", "text": "The Synthwave Collective", "styleId": "artistName" }
              ]
            },
            { "type": "spacer" },
            { "type": "button", "text": "Queue", "styleId": "queueButton", "actions": { "onTap": "toggleQueue" } }
          ]
        },
        {
          "type": "vstack", "spacing": 8,
          "children": [
            { "type": "slider", "bind": "currentTime", "minValue": 0, "maxValue": 245, "styleId": "progressBar" },
            {
              "type": "hstack",
              "children": [
                { "type": "label", "dataSourceId": "currentTimeText", "styleId": "timeLabel" },
                { "type": "spacer" },
                { "type": "label", "dataSourceId": "durationText", "styleId": "timeLabel" }
              ]
            }
          ]
        },
        {
          "type": "hstack", "spacing": 32,
          "children": [
            {
              "type": "button",
              "styles": { "normal": "shuffleButton", "selected": "shuffleButtonActive" },
              "isSelectedBinding": "isShuffled",
              "actions": { "onTap": "toggleShuffle" },
              "children": [{
                "type": "image",
                "image": { "system": "shuffle" },
                "styles": { "normal": "shuffleIcon", "selected": "shuffleIconActive" },
                "isSelectedBinding": "isShuffled"
              }]
            },
            {
              "type": "button",
              "actions": { "onTap": "skipPrevious" },
              "children": [{ "type": "image", "image": { "system": "backward.fill" }, "styleId": "skipIcon" }]
            },
            {
              "type": "button", "styleId": "playButton",
              "actions": { "onTap": "togglePlay" },
              "children": [{
                "type": "image",
                "image": { "system": "play.fill" },
                "styleId": "playIcon"
              }]
            },
            {
              "type": "button",
              "actions": { "onTap": "skipNext" },
              "children": [{ "type": "image", "image": { "system": "forward.fill" }, "styleId": "skipIcon" }]
            },
            {
              "type": "button", "styleId": "shuffleButton",
              "children": [{
                "type": "image", "image": { "system": "repeat" }, "styleId": "shuffleIcon"
              }]
            }
          ]
        },
        {
          "type": "hstack", "spacing": 12,
          "children": [
            { "type": "image", "image": { "system": "speaker.fill" }, "styleId": "volumeIcon" },
            { "type": "slider", "bind": "volume", "minValue": 0, "maxValue": 1, "styleId": "volumeSlider" },
            { "type": "image", "image": { "system": "speaker.wave.3.fill" }, "styleId": "volumeIcon" }
          ]
        },
        {
          "type": "sectionLayout",
          "sectionSpacing": 0,
          "sections": [{
            "id": "queue",
            "layout": { "type": "list", "showsDividers": true, "itemSpacing": 0 },
            "header": {
              "type": "hstack", "padding": { "vertical": 12 },
              "children": [
                { "type": "label", "text": "Up Next", "styleId": "songTitle" },
                { "type": "spacer" }
              ]
            },
            "children": [
              {
                "type": "hstack", "spacing": 12, "styleId": "queueItem",
                "children": [
                  {
                    "type": "zstack", "styleId": "queueImage",
                    "children": [{ "type": "image", "image": { "system": "music.note" }, "styleId": "queueIcon" }]
                  },
                  {
                    "type": "vstack", "spacing": 2, "alignment": "leading",
                    "children": [
                      {
                        "type": "hstack", "spacing": 8,
                        "children": [
                          { "type": "label", "text": "Neon Lights", "styleId": "queueTitle" },
                          { "type": "label", "text": "NOW", "styleId": "nowPlayingBadge" }
                        ]
                      },
                      { "type": "label", "text": "Electric Pulse", "styleId": "queueArtist" }
                    ]
                  },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack", "spacing": 12, "styleId": "queueItem",
                "children": [
                  {
                    "type": "zstack", "styleId": "queueImage",
                    "children": [{ "type": "image", "image": { "system": "music.note" }, "styleId": "queueIcon" }]
                  },
                  {
                    "type": "vstack", "spacing": 2, "alignment": "leading",
                    "children": [
                      { "type": "label", "text": "Digital Sunrise", "styleId": "queueTitle" },
                      { "type": "label", "text": "Retro Wave", "styleId": "queueArtist" }
                    ]
                  },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "hstack", "spacing": 12, "styleId": "queueItem",
                "children": [
                  {
                    "type": "zstack", "styleId": "queueImage",
                    "children": [{ "type": "image", "image": { "system": "music.note" }, "styleId": "queueIcon" }]
                  },
                  {
                    "type": "vstack", "spacing": 2, "alignment": "leading",
                    "children": [
                      { "type": "label", "text": "Cosmic Journey", "styleId": "queueTitle" },
                      { "type": "label", "text": "Space Synth", "styleId": "queueArtist" }
                    ]
                  },
                  { "type": "spacer" }
                ]
              }
            ]
          }]
        }
      ]
    }]
  }
}
"""

// MARK: Weather Dashboard

let weatherDashboardJSON = """
{
  "id": "weather-dashboard",
  "version": "1.0",
  "state": {
    "location": "Loading...",
    "currentDate": "Loading...",
    "temperature": 72,
    "feelsLike": 68,
    "humidity": 65,
    "windSpeed": 12,
    "uvIndex": 6,
    "visibility": 10,
    "condition": "Partly Cloudy",
    "conditionIcon": "cloud.sun.fill",
    "isLoading": true,
    "selectedDay": 0,
    "hour0Temp": "--°",
    "hour0Label": "Now",
    "hour1Temp": "--°",
    "hour1Label": "--",
    "hour2Temp": "--°",
    "hour2Label": "--",
    "hour3Temp": "--°",
    "hour3Label": "--",
    "hour4Temp": "--°",
    "hour4Label": "--",
    "hour5Temp": "--°",
    "hour5Label": "--",
    "day0High": "--°",
    "day0Low": " / --°",
    "day0Label": "Today",
    "day1High": "--°",
    "day1Low": " / --°",
    "day1Label": "--",
    "day2High": "--°",
    "day2Low": " / --°",
    "day2Label": "--",
    "day3High": "--°",
    "day3Low": " / --°",
    "day3Label": "--",
    "day4High": "--°",
    "day4Low": " / --°",
    "day4Label": "--"
  },
  "styles": {
    "screenBg": {
      "backgroundColor": "#1E3A5F"
    },
    "locationText": { "fontSize": 28, "fontWeight": "bold", "textColor": "#FFFFFF" },
    "dateText": { "fontSize": 14, "textColor": "#D0D0D0" },
    "tempLarge": { "fontSize": 96, "fontWeight": "thin", "textColor": "#FFFFFF" },
    "tempUnit": { "fontSize": 32, "fontWeight": "light", "textColor": "#D0D0D0" },
    "conditionText": { "fontSize": 20, "fontWeight": "medium", "textColor": "#FFFFFF" },
    "feelsLikeText": { "fontSize": 14, "textColor": "#D0D0D0" },
    "weatherIcon": { "width": 64, "height": 64, "tintColor": "#FFD700" },
    "statCard": {
      "backgroundColor": "rgba(255,255,255,0.15)", "cornerRadius": 16,
      "padding": { "all": 16 }
    },
    "statIcon": { "width": 24, "height": 24, "tintColor": "#FFFFFF" },
    "statValue": { "fontSize": 20, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "statLabel": { "fontSize": 12, "textColor": "#D0D0D0" },
    "hourCard": {
      "backgroundColor": "rgba(255,255,255,0.1)", "cornerRadius": 20,
      "padding": { "horizontal": 16, "vertical": 20 }, "width": 70
    },
    "hourCardSelected": {
      "backgroundColor": "rgba(255,255,255,0.3)", "cornerRadius": 20,
      "padding": { "horizontal": 16, "vertical": 20 }, "width": 70
    },
    "hourText": { "fontSize": 14, "fontWeight": "medium", "textColor": "#D0D0D0" },
    "hourTemp": { "fontSize": 18, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "hourIcon": { "width": 28, "height": 28, "tintColor": "#FFD700" },
    "dayRow": { "padding": { "vertical": 12 } },
    "dayName": { "fontSize": 16, "fontWeight": "medium", "textColor": "#FFFFFF", "width": 80 },
    "dayIcon": { "width": 28, "height": 28, "tintColor": "#FFD700" },
    "dayTempHigh": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "dayTempLow": { "fontSize": 16, "textColor": "#B0B0B0" },
    "sectionTitle": { "fontSize": 16, "fontWeight": "semibold", "textColor": "#D0D0D0" },
    "sunTimeCard": {
      "backgroundColor": "rgba(255,255,255,0.1)", "cornerRadius": 16,
      "padding": { "all": 16 }
    },
    "sunIcon": { "width": 32, "height": 32, "tintColor": "#FFD700" },
    "sunTime": { "fontSize": 24, "fontWeight": "semibold", "textColor": "#FFFFFF" },
    "sunLabel": { "fontSize": 12, "textColor": "#D0D0D0" },
    "closeButton": { "width": 28, "height": 28, "tintColor": "#D0D0D0" }
  },
  "actions": {
    "close": { "type": "dismiss" },
    "fetchWeather": { "type": "fetchWeather" },
    "selectToday": { "type": "setState", "path": "selectedDay", "value": 0 },
    "selectTomorrow": { "type": "setState", "path": "selectedDay", "value": 1 },
    "refreshWeather": { "type": "fetchWeather" }
  },
  "dataSources": {
    "locationDisplay": { "type": "binding", "path": "location" },
    "dateDisplay": { "type": "binding", "path": "currentDate" },
    "tempDisplay": { "type": "binding", "template": "${temperature}" },
    "conditionDisplay": { "type": "binding", "path": "condition" },
    "feelsLikeDisplay": { "type": "binding", "template": "Feels like ${feelsLike}°" },
    "humidityDisplay": { "type": "binding", "template": "${humidity}%" },
    "windDisplay": { "type": "binding", "template": "${windSpeed} mph" },
    "uvDisplay": { "type": "binding", "template": "${uvIndex}" },
    "visibilityDisplay": { "type": "binding", "template": "${visibility} mi" },
    "hour0Label": { "type": "binding", "path": "hour0Label" },
    "hour0Temp": { "type": "binding", "path": "hour0Temp" },
    "hour1Label": { "type": "binding", "path": "hour1Label" },
    "hour1Temp": { "type": "binding", "path": "hour1Temp" },
    "hour2Label": { "type": "binding", "path": "hour2Label" },
    "hour2Temp": { "type": "binding", "path": "hour2Temp" },
    "hour3Label": { "type": "binding", "path": "hour3Label" },
    "hour3Temp": { "type": "binding", "path": "hour3Temp" },
    "hour4Label": { "type": "binding", "path": "hour4Label" },
    "hour4Temp": { "type": "binding", "path": "hour4Temp" },
    "hour5Label": { "type": "binding", "path": "hour5Label" },
    "hour5Temp": { "type": "binding", "path": "hour5Temp" },
    "day0Label": { "type": "binding", "path": "day0Label" },
    "day0High": { "type": "binding", "path": "day0High" },
    "day0Low": { "type": "binding", "path": "day0Low" },
    "day1Label": { "type": "binding", "path": "day1Label" },
    "day1High": { "type": "binding", "path": "day1High" },
    "day1Low": { "type": "binding", "path": "day1Low" },
    "day2Label": { "type": "binding", "path": "day2Label" },
    "day2High": { "type": "binding", "path": "day2High" },
    "day2Low": { "type": "binding", "path": "day2Low" },
    "day3Label": { "type": "binding", "path": "day3Label" },
    "day3High": { "type": "binding", "path": "day3High" },
    "day3Low": { "type": "binding", "path": "day3Low" },
    "day4Label": { "type": "binding", "path": "day4Label" },
    "day4High": { "type": "binding", "path": "day4High" },
    "day4Low": { "type": "binding", "path": "day4Low" }
  },
  "root": {
    "actions": {
      "onAppear": "fetchWeather"
    },
    "children": [{
      "type": "zstack",
      "children": [
        {
          "type": "gradient",
          "gradientColors": [
            { "color": "#1E3A5F", "location": 0.0 },
            { "color": "#2E5077", "location": 0.5 },
            { "color": "#4A7C9B", "location": 1.0 }
          ],
          "gradientStart": "top", "gradientEnd": "bottom",
          "ignoresSafeArea": true
        },
        {
          "type": "sectionLayout",
          "sectionSpacing": 24,
          "sections": [
            {
              "id": "header",
              "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20, "top": 20 } },
              "children": [
                {
                  "type": "hstack",
                  "children": [
                    {
                      "type": "vstack", "spacing": 4, "alignment": "leading",
                      "children": [
                        { "type": "label", "dataSourceId": "locationDisplay", "styleId": "locationText" },
                        { "type": "label", "dataSourceId": "dateDisplay", "styleId": "dateText" }
                      ]
                    },
                    { "type": "spacer" },
                    {
                      "type": "button",
                      "actions": { "onTap": "close" },
                      "children": [{ "type": "image", "image": { "system": "xmark.circle.fill" }, "styleId": "closeButton" }]
                    }
                  ]
                }
              ]
            },
            {
              "id": "current",
              "layout": { "type": "list", "showsDividers": false, "contentInsets": { "horizontal": 20 } },
              "children": [
                {
                  "type": "hstack",
                  "children": [
                    {
                      "type": "vstack", "alignment": "leading",
                      "children": [
                        {
                          "type": "hstack", "alignment": "top",
                          "children": [
                            { "type": "label", "dataSourceId": "tempDisplay", "styleId": "tempLarge" },
                            { "type": "label", "text": "°", "styleId": "tempUnit" }
                          ]
                        },
                        { "type": "label", "dataSourceId": "conditionDisplay", "styleId": "conditionText" },
                        { "type": "label", "dataSourceId": "feelsLikeDisplay", "styleId": "feelsLikeText" }
                      ]
                    },
                    { "type": "spacer" },
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "weatherIcon" }
                  ]
                }
              ]
            },
            {
              "id": "stats",
              "layout": { "type": "grid", "columns": 2, "itemSpacing": 12, "lineSpacing": 12, "contentInsets": { "horizontal": 20 } },
              "children": [
                {
                  "type": "hstack", "spacing": 12, "styleId": "statCard",
                  "children": [
                    { "type": "image", "image": { "system": "humidity.fill" }, "styleId": "statIcon" },
                    {
                      "type": "vstack", "spacing": 2, "alignment": "leading",
                      "children": [
                        { "type": "label", "dataSourceId": "humidityDisplay", "styleId": "statValue" },
                        { "type": "label", "text": "Humidity", "styleId": "statLabel" }
                      ]
                    }
                  ]
                },
                {
                  "type": "hstack", "spacing": 12, "styleId": "statCard",
                  "children": [
                    { "type": "image", "image": { "system": "wind" }, "styleId": "statIcon" },
                    {
                      "type": "vstack", "spacing": 2, "alignment": "leading",
                      "children": [
                        { "type": "label", "dataSourceId": "windDisplay", "styleId": "statValue" },
                        { "type": "label", "text": "Wind", "styleId": "statLabel" }
                      ]
                    }
                  ]
                },
                {
                  "type": "hstack", "spacing": 12, "styleId": "statCard",
                  "children": [
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "statIcon" },
                    {
                      "type": "vstack", "spacing": 2, "alignment": "leading",
                      "children": [
                        { "type": "label", "dataSourceId": "uvDisplay", "styleId": "statValue" },
                        { "type": "label", "text": "UV Index", "styleId": "statLabel" }
                      ]
                    }
                  ]
                },
                {
                  "type": "hstack", "spacing": 12, "styleId": "statCard",
                  "children": [
                    { "type": "image", "image": { "system": "eye.fill" }, "styleId": "statIcon" },
                    {
                      "type": "vstack", "spacing": 2, "alignment": "leading",
                      "children": [
                        { "type": "label", "dataSourceId": "visibilityDisplay", "styleId": "statValue" },
                        { "type": "label", "text": "Visibility", "styleId": "statLabel" }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "id": "hourly",
              "layout": { "type": "horizontal", "itemSpacing": 12, "contentInsets": { "horizontal": 20 } },
              "header": { "type": "label", "text": "HOURLY FORECAST", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
              "children": [
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCardSelected",
                  "children": [
                    { "type": "label", "dataSourceId": "hour0Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour0Temp", "styleId": "hourTemp" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCard",
                  "children": [
                    { "type": "label", "dataSourceId": "hour1Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "cloud.sun.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour1Temp", "styleId": "hourTemp" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCard",
                  "children": [
                    { "type": "label", "dataSourceId": "hour2Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "cloud.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour2Temp", "styleId": "hourTemp" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCard",
                  "children": [
                    { "type": "label", "dataSourceId": "hour3Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "cloud.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour3Temp", "styleId": "hourTemp" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCard",
                  "children": [
                    { "type": "label", "dataSourceId": "hour4Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "cloud.sun.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour4Temp", "styleId": "hourTemp" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "hourCard",
                  "children": [
                    { "type": "label", "dataSourceId": "hour5Label", "styleId": "hourText" },
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "hourIcon" },
                    { "type": "label", "dataSourceId": "hour5Temp", "styleId": "hourTemp" }
                  ]
                }
              ]
            },
            {
              "id": "sunrise-sunset",
              "layout": { "type": "horizontal", "itemSpacing": 12, "contentInsets": { "horizontal": 20 } },
              "children": [
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "sunTimeCard",
                  "children": [
                    { "type": "image", "image": { "system": "sunrise.fill" }, "styleId": "sunIcon" },
                    { "type": "label", "text": "6:52 AM", "styleId": "sunTime" },
                    { "type": "label", "text": "Sunrise", "styleId": "sunLabel" }
                  ]
                },
                {
                  "type": "vstack", "spacing": 8, "alignment": "center", "styleId": "sunTimeCard",
                  "children": [
                    { "type": "image", "image": { "system": "sunset.fill" }, "styleId": "sunIcon" },
                    { "type": "label", "text": "5:18 PM", "styleId": "sunTime" },
                    { "type": "label", "text": "Sunset", "styleId": "sunLabel" }
                  ]
                }
              ]
            },
            {
              "id": "weekly",
              "layout": { "type": "list", "showsDividers": false, "itemSpacing": 0, "contentInsets": { "horizontal": 20, "bottom": 40 } },
              "header": { "type": "label", "text": "5-DAY FORECAST", "styleId": "sectionTitle", "padding": { "bottom": 12 } },
              "children": [
                {
                  "type": "hstack", "styleId": "dayRow",
                  "children": [
                    { "type": "label", "dataSourceId": "day0Label", "styleId": "dayName" },
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "dayIcon" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "day0High", "styleId": "dayTempHigh" },
                    { "type": "label", "dataSourceId": "day0Low", "styleId": "dayTempLow" }
                  ]
                },
                {
                  "type": "hstack", "styleId": "dayRow",
                  "children": [
                    { "type": "label", "dataSourceId": "day1Label", "styleId": "dayName" },
                    { "type": "image", "image": { "system": "cloud.sun.fill" }, "styleId": "dayIcon" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "day1High", "styleId": "dayTempHigh" },
                    { "type": "label", "dataSourceId": "day1Low", "styleId": "dayTempLow" }
                  ]
                },
                {
                  "type": "hstack", "styleId": "dayRow",
                  "children": [
                    { "type": "label", "dataSourceId": "day2Label", "styleId": "dayName" },
                    { "type": "image", "image": { "system": "cloud.rain.fill" }, "styleId": "dayIcon" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "day2High", "styleId": "dayTempHigh" },
                    { "type": "label", "dataSourceId": "day2Low", "styleId": "dayTempLow" }
                  ]
                },
                {
                  "type": "hstack", "styleId": "dayRow",
                  "children": [
                    { "type": "label", "dataSourceId": "day3Label", "styleId": "dayName" },
                    { "type": "image", "image": { "system": "cloud.fill" }, "styleId": "dayIcon" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "day3High", "styleId": "dayTempHigh" },
                    { "type": "label", "dataSourceId": "day3Low", "styleId": "dayTempLow" }
                  ]
                },
                {
                  "type": "hstack", "styleId": "dayRow",
                  "children": [
                    { "type": "label", "dataSourceId": "day4Label", "styleId": "dayName" },
                    { "type": "image", "image": { "system": "sun.max.fill" }, "styleId": "dayIcon" },
                    { "type": "spacer" },
                    { "type": "label", "dataSourceId": "day4High", "styleId": "dayTempHigh" },
                    { "type": "label", "dataSourceId": "day4Low", "styleId": "dayTempLow" }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }]
  }
}
"""
