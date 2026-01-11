//
//  PhotoTouchUpJSON.swift
//  CladsExamples
//
//  JSON definition for the Photo Touch Up bottom sheet.
//

import Foundation

public enum PhotoTouchUpJSON {

    public static let bottomSheet = """
    {
      "id": "photoTouchUp",
      "root": {
        "backgroundColor": "#FFFFFF",
        "children": [
          {
            "type": "vstack",
            "spacing": 0,
            "padding": { "horizontal": 0, "top": 0, "bottom": 0 },
            "children": [
              {
                "type": "hstack",
                "padding": { "horizontal": 16, "top": 16, "bottom": 0 },
                "children": [
                  {
                    "type": "closeButton",
                    "actions": { "onTap": "dismiss" }
                  },
                  { "type": "spacer" }
                ]
              },
              {
                "type": "vstack",
                "spacing": 24,
                "padding": { "horizontal": 24, "top": 0, "bottom": 32 },
                "alignment": "center",
                "children": [
                  {
                    "type": "photoComparison",
                    "styleId": "photoComparison",
                    "data": {
                      "beforeImage": { "type": "static", "value": "touchUpBefore" },
                      "afterImage": { "type": "static", "value": "touchUpAfter" }
                    }
                  },
                  {
                    "type": "vstack",
                    "spacing": 8,
                    "alignment": "center",
                    "children": [
                      {
                        "type": "label",
                        "text": "Your photo is now",
                        "styleId": "titleStyle"
                      },
                      {
                        "type": "label",
                        "text": "touched up",
                        "styleId": "titleStyle"
                      }
                    ]
                  },
                  {
                    "type": "vstack",
                    "spacing": 4,
                    "alignment": "center",
                    "children": [
                      {
                        "type": "label",
                        "text": "We improved clarity on one of your photos to help it look its best. You're always in control—review, adjust, or turn it off at anytime.",
                        "styleId": "bodyStyle"
                      },
                      {
                        "type": "button",
                        "text": "Learn more about touch ups",
                        "styleId": "linkButton",
                        "actions": { "onTap": "learnMore" }
                      }
                    ]
                  },
                  {
                    "type": "button",
                    "text": "Review",
                    "styleId": "primaryButton",
                    "fillWidth": true,
                    "actions": { "onTap": "review" }
                  }
                ]
              }
            ]
          }
        ]
      },
      "styles": {
        "photoComparison": {
          "width": 200,
          "height": 267
        },
        "titleStyle": {
          "fontSize": 28,
          "fontWeight": "bold",
          "textColor": "#1A1A1A",
          "textAlignment": "center"
        },
        "bodyStyle": {
          "fontSize": 14,
          "fontWeight": "regular",
          "textColor": "#666666",
          "textAlignment": "center"
        },
        "linkButton": {
          "fontSize": 14,
          "fontWeight": "regular",
          "textColor": "#1A1A1A"
        },
        "primaryButton": {
          "fontSize": 16,
          "fontWeight": "semibold",
          "textColor": "#FFFFFF",
          "backgroundColor": "#1A1A1A",
          "cornerRadius": 28,
          "height": 56
        }
      },
      "actions": {
        "dismiss": { "type": "dismiss" },
        "learnMore": { "type": "learnMore" },
        "review": { "type": "review" }
      }
    }
    """
}

