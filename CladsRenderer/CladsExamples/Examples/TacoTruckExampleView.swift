//
//  TacoTruckExampleView.swift
//  CladsRenderer
//
//  Example demonstrating typed state binding and callbacks.
//

import CLADS
import CladsModules
import SwiftUI

// MARK: - State Model

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

// MARK: - Taco Truck Example View

/// Example view demonstrating:
/// - CladsRendererBindingView with typed state
/// - Bidirectional state sync via Binding
/// - State change callbacks for analytics
/// - Real-time state display
public struct TacoTruckExampleView: View {
    @Environment(\.dismiss) private var dismiss

    // Typed state that syncs with the CLADS view
    @State private var orderState = TacoOrderState()

    // Analytics/debug log
    @State private var stateChanges: [(path: String, value: String)] = []

    public var body: some View {
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
            let config = CladsRendererBindingConfiguration<TacoOrderState>(
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
                }
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

// MARK: - State Badge

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

// MARK: - JSON

let tacoTruckJSON = """
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

// MARK: - Preview

#Preview {
    TacoTruckExampleView()
}
