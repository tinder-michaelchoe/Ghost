//
//  FeedbackSurveyJSON.swift
//  CladsExamples
//
//  JSON definition for the Feedback Survey bottom sheet.
//

import Foundation

public enum FeedbackSurveyJSON {

    public static let bottomSheet = """
    {
      "id": "feedbackSurvey",
      "version": "1.0",
      "state": {
        "selectedOption": ""
      },
      "root": {
        "backgroundColor": "#FFFFFF",
        "cornerRadius": 24,
        "children": [
          {
            "type": "vstack",
            "spacing": 0,
            "children": [
              {
                "type": "hstack",
                "padding": { "horizontal": 16, "top": 16, "bottom": 0 },
                "children": [
                  {
                    "type": "closeButton",
                    "actions": { "onTap": "dismiss" }
                  },
                  { "type": "spacer" },
                  {
                    "type": "label",
                    "text": "Help us improve",
                    "styleId": "headerTitle"
                  },
                  { "type": "spacer" },
                  {
                    "type": "vstack",
                    "styleId": "placeholderSpacer",
                    "children": []
                  }
                ]
              },
              {
                "type": "vstack",
                "spacing": 24,
                "padding": { "horizontal": 24, "top": 24, "bottom": 32 },
                "alignment": "leading",
                "children": [
                  {
                    "type": "label",
                    "text": "Why don't you want your photo enhanced?",
                    "styleId": "questionTitle"
                  },
                  {
                    "type": "vstack",
                    "spacing": 0,
                    "styleId": "optionsContainer",
                    "children": [
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "It didn't look like me", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'didnt_look_like_me'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "didnt_look_like_me" } }
                          }
                        ]
                      },
                      { "type": "divider", "styleId": "rowDivider" },
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "It looked overly edited", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'overly_edited'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "overly_edited" } }
                          }
                        ]
                      },
                      { "type": "divider", "styleId": "rowDivider" },
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "I didn't notice a difference", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'no_difference'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "no_difference" } }
                          }
                        ]
                      },
                      { "type": "divider", "styleId": "rowDivider" },
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "I prefer my original photo", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'prefer_original'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "prefer_original" } }
                          }
                        ]
                      },
                      { "type": "divider", "styleId": "rowDivider" },
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "I don't like editing my photos", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'dont_like_editing'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "dont_like_editing" } }
                          }
                        ]
                      },
                      { "type": "divider", "styleId": "rowDivider" },
                      {
                        "type": "hstack",
                        "padding": { "vertical": 16, "horizontal": 16 },
                        "children": [
                          { "type": "label", "text": "Other", "styleId": "optionText" },
                          { "type": "spacer" },
                          {
                            "type": "button",
                            "text": "",
                            "styles": { "normal": "radioButtonNormal", "selected": "radioButtonSelected" },
                            "isSelectedBinding": "${selectedOption == 'other'}",
                            "actions": { "onTap": { "type": "setState", "path": "selectedOption", "value": "other" } }
                          }
                        ]
                      }
                    ]
                  },
                  {
                    "type": "button",
                    "text": "Submit",
                    "styleId": "submitButton",
                    "fillWidth": true,
                    "actions": { "onTap": "submitFeedback" }
                  }
                ]
              }
            ]
          }
        ]
      },
      "styles": {
        "headerTitle": {
          "fontSize": 16,
          "fontWeight": "semibold",
          "textColor": "#1A1A1A",
          "textAlignment": "center"
        },
        "placeholderSpacer": {
          "width": 32,
          "height": 32
        },
        "questionTitle": {
          "fontSize": 28,
          "fontWeight": "bold",
          "textColor": "#1A1A1A",
          "textAlignment": "leading"
        },
        "optionsContainer": {
          "backgroundColor": "#F5F5F5",
          "cornerRadius": 16
        },
        "optionText": {
          "fontSize": 17,
          "fontWeight": "regular",
          "textColor": "#1A1A1A"
        },
        "radioButtonNormal": {
          "width": 24,
          "height": 24,
          "cornerRadius": 12,
          "borderWidth": 2,
          "borderColor": "#CCCCCC",
          "backgroundColor": "transparent"
        },
        "radioButtonSelected": {
          "width": 24,
          "height": 24,
          "cornerRadius": 12,
          "backgroundColor": "#1A1A1A"
        },
        "rowDivider": {
          "height": 1,
          "backgroundColor": "#E0E0E0"
        },
        "submitButton": {
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
        "submitFeedback": {
          "type": "sequence",
          "steps": [
            { "type": "dismiss" },
            {
              "type": "showAlert",
              "title": "Feedback Submitted",
              "message": { "type": "binding", "template": "You selected: ${selectedOption}" },
              "buttons": [
                { "label": "OK", "style": "default" }
              ]
            }
          ]
        }
      }
    }
    """
}
