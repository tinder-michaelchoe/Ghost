//
//  BirdsExampleView.swift
//  CladsRenderer
//
//  Example view demonstrating horizontal scrolling cards with the Nuthatch Birds API.
//

import CLADS
import CladsModules
import SwiftUI

// MARK: - Birds Example View

public struct BirdsExampleView: View {
    @State private var featuredBirds: [Bird] = []
    @State private var watchlistBirds: [Bird] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    public var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading birds...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await loadBirds() }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                birdsDocumentView
            }
        }
        .task {
            await loadBirds()
        }
    }

    @ViewBuilder
    private var birdsDocumentView: some View {
        let json = buildBirdsJSON()
        if let view = CladsRendererView(jsonString: json, debugMode: true) {
            view
        } else {
            Text("Failed to parse document")
        }
    }

    // MARK: - Data Loading

    private func loadBirds() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch birds with images from the API
            let allBirdsWithImages = try await fetchBirdsWithImages(limit: 25)

            // Randomly select 5 for "Birds of the Month"
            featuredBirds = Array(allBirdsWithImages.shuffled().prefix(5))

            // Use remaining birds for "Watchlist" (up to 20)
            let remainingBirds = allBirdsWithImages.filter { bird in
                !featuredBirds.contains { $0.id == bird.id }
            }
            watchlistBirds = Array(remainingBirds.prefix(20))

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchBirdsWithImages(limit: Int) async throws -> [Bird] {
        let url = URL(string: "https://nuthatch.lastelm.software/v2/birds?hasImg=true&pageSize=\(limit)")!
        var request = URLRequest(url: url)
        request.setValue("24b65f73-39ee-4c32-910c-be4c4e2a0951", forHTTPHeaderField: "API-Key")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdsResponse.self, from: data)
        return response.entities
    }

    // MARK: - JSON Builder

    private func buildBirdsJSON() -> String {
        let featuredChildren = featuredBirds.map { bird in
            """
            {
              "type": "vstack",
              "styleId": "birdCard",
              "spacing": 0,
              "children": [
                {
                  "type": "image",
                  "image": { "url": "\(bird.images.first ?? "https://via.placeholder.com/300x200?text=No+Image")" },
                  "styleId": "cardImage"
                },
                {
                  "type": "vstack",
                  "padding": { "all": 12 },
                  "spacing": 4,
                  "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "\(escapeJSON(bird.name))", "styleId": "cardTitle" },
                    { "type": "label", "text": "\(escapeJSON(bird.sciName))", "styleId": "cardSubtitle" }
                  ]
                }
              ]
            }
            """
        }.joined(separator: ",\n")

        let watchlistChildren = watchlistBirds.map { bird in
            """
            {
              "type": "hstack",
              "spacing": 12,
              "alignment": { "vertical": "center" },
              "children": [
                {
                  "type": "image",
                  "image": { "url": "\(bird.images.first ?? "https://via.placeholder.com/60x60?text=No+Image")" },
                  "styleId": "listImage"
                },
                {
                  "type": "vstack",
                  "spacing": 2,
                  "alignment": "leading",
                  "children": [
                    { "type": "label", "text": "\(escapeJSON(bird.name))", "styleId": "listTitle" },
                    { "type": "label", "text": "\(escapeJSON(bird.sciName))", "styleId": "listSubtitle" }
                  ]
                }
              ]
            }
            """
        }.joined(separator: ",\n")

        return """
        {
          "id": "birds-example",
          "version": "1.0",

          "styles": {
            "screenTitle": {
              "fontSize": 34,
              "fontWeight": "bold",
              "textColor": "#000000"
            },
            "sectionTitle": {
              "fontSize": 22,
              "fontWeight": "bold",
              "textColor": "#000000"
            },
            "birdCard": {
              "backgroundColor": "#FFFFFF",
              "cornerRadius": 16
            },
            "cardImage": {
              "cornerRadius": 0,
              "height": 160
            },
            "cardTitle": {
              "fontSize": 17,
              "fontWeight": "semibold",
              "textColor": "#000000"
            },
            "cardSubtitle": {
              "fontSize": 14,
              "textColor": "#8E8E93"
            },
            "listImage": {
              "width": 60,
              "height": 60,
              "cornerRadius": 8
            },
            "listTitle": {
              "fontSize": 17,
              "fontWeight": "medium",
              "textColor": "#000000"
            },
            "listSubtitle": {
              "fontSize": 14,
              "textColor": "#8E8E93"
            }
          },

          "root": {
            "backgroundColor": "#F2F2F7",
            "children": [
              {
                "type": "sectionLayout",
                "sectionSpacing": 24,
                "sections": [
                  {
                    "id": "featured",
                    "layout": {
                      "type": "horizontal",
                      "itemSpacing": 16,
                      "contentInsets": { "horizontal": 16 },
                      "itemDimensions": {
                        "width": { "fractional": 0.8 },
                        "aspectRatio": 1.3
                      },
                      "snapBehavior": "viewAligned"
                    },
                    "header": {
                      "type": "label",
                      "text": "Birds of the Month",
                      "styleId": "sectionTitle",
                      "padding": { "bottom": 12, "leading": 16 }
                    },
                    "children": [
                      \(featuredChildren)
                    ]
                  },
                  {
                    "id": "watchlist",
                    "layout": {
                      "type": "list",
                      "itemSpacing": 0,
                      "showsDividers": true,
                      "contentInsets": { "horizontal": 16 }
                    },
                    "header": {
                      "type": "label",
                      "text": "Watchlist",
                      "styleId": "sectionTitle",
                      "padding": { "bottom": 12, "leading": 16 }
                    },
                    "children": [
                      \(watchlistChildren)
                    ]
                  }
                ]
              }
            ]
          }
        }
        """
    }

    private func escapeJSON(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// MARK: - API Models

struct Bird: Codable {
    let id: Int
    let name: String
    let sciName: String
    let images: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sciName
        case images
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        sciName = try container.decode(String.self, forKey: .sciName)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
    }
}

struct BirdsResponse: Codable {
    let entities: [Bird]
}

// MARK: - Preview

#Preview {
    BirdsExampleView()
}
