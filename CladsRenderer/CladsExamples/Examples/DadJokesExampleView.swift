//
//  DadJokesExampleView.swift
//  CladsRenderer
//
//  Example demonstrating custom action closures for REST API calls.
//

import CLADS
import CladsModules
import SwiftUI

// MARK: - Dad Jokes Example View

/// Example demonstrating:
/// - Custom action closures for REST API calls
/// - State updates from network responses
/// - Fun reveal animation with punchline
public struct DadJokesExampleView: View {
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
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

// MARK: - Helper Functions

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
    return (joke, "")
}

// MARK: - JSON

let dadJokesJSON = """
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

// MARK: - Preview

#Preview {
    DadJokesExampleView()
}
