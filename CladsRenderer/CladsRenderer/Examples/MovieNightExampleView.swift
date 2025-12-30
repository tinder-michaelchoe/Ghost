//
//  MovieNightExampleView.swift
//  CladsRenderer
//
//  Example demonstrating UIKit renderer with delegate pattern.
//

import CLADS
import SwiftUI
import UIKit

// MARK: - Movie Night Example View

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

// MARK: - UIKit View Representable

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

// MARK: - Custom View Controller

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

// MARK: - JSON

let movieNightJSON = """
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

// MARK: - Preview

#Preview {
    MovieNightExampleView()
}
