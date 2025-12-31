//
//  ArtService.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import Foundation
import UIKit

// MARK: - Art Service Protocol

/// Protocol for searching and fetching artwork.
public protocol ArtSearching: Sendable {
    /// Searches for portrait artwork matching the given weather condition.
    /// Tries keywords in order until a portrait artwork is found.
    /// - Parameter condition: The weather condition to search for
    /// - Returns: An artwork with the keyword that found it
    func searchArt(for condition: WeatherCondition) async throws -> ArtSearchResult

    /// Searches for "art of the day" when weather-based search fails.
    /// - Returns: An artwork with the fallback keyword used
    func searchArtOfTheDay() async throws -> ArtSearchResult

    /// Fetches the image for an artwork.
    /// - Parameter artwork: The artwork to fetch the image for
    /// - Returns: The artwork image
    func fetchImage(for artwork: Artwork) async throws -> UIImage
}

// MARK: - Art Service Implementation

/// Implementation of ArtSearching using the Art Institute of Chicago API.
public final class ArtService: ArtSearching, @unchecked Sendable {

    // MARK: - Properties

    private let networkClient: NetworkRequestPerforming
    private static let baseURL = "https://api.artic.edu/api/v1"

    /// Tracks which keyword index to try next for each condition.
    /// Used for refresh functionality - try next keyword on refresh.
    private var keywordIndices: [WeatherCondition: Int] = [:]
    private let lock = NSLock()

    // MARK: - Init

    public init(networkClient: NetworkRequestPerforming) {
        self.networkClient = networkClient
    }

    // MARK: - ArtSearching

    public func searchArt(for condition: WeatherCondition) async throws -> ArtSearchResult {
        let keywords = WeatherArtKeywords.keywords(for: condition)
        let startIndex = nextKeywordIndex(for: condition, totalKeywords: keywords.count)

        // Try keywords starting from the current index, wrapping around
        for offset in 0..<keywords.count {
            let index = (startIndex + offset) % keywords.count
            let keyword = keywords[index]

            if let artwork = try await searchPortraitArtwork(keyword: keyword) {
                return ArtSearchResult(artwork: artwork, keyword: keyword)
            }
        }

        // No artwork found for any keyword
        throw ArtError.noArtworkFound
    }

    public func searchArtOfTheDay() async throws -> ArtSearchResult {
        let keywords = WeatherArtKeywords.fallbackKeywords

        for keyword in keywords {
            if let artwork = try await searchPortraitArtwork(keyword: keyword) {
                return ArtSearchResult(artwork: artwork, keyword: keyword)
            }
        }

        throw ArtError.noArtworkFound
    }

    public func fetchImage(for artwork: Artwork) async throws -> UIImage {
        guard let url = artwork.imageURL() else {
            print("[ArtService] Failed to create image URL for artwork: \(artwork.imageId)")
            throw ArtError.imageLoadFailed
        }

        print("[ArtService] Fetching image from: \(url)")

        let request = NetworkRequest.get(url, headers: [:])

        do {
            let (data, _) = try await networkClient.performRaw(request)
            print("[ArtService] Received \(data.count) bytes of image data")

            guard let image = UIImage(data: data) else {
                print("[ArtService] Failed to create UIImage from data")
                throw ArtError.imageLoadFailed
            }

            print("[ArtService] Successfully loaded image: \(image.size)")
            return image
        } catch {
            print("[ArtService] Image fetch error: \(error)")
            throw error
        }
    }

    // MARK: - Private

    private func searchPortraitArtwork(keyword: String) async throws -> Artwork? {
        guard var components = URLComponents(string: "\(Self.baseURL)/artworks/search") else {
            print("[ArtService] Failed to create URL components")
            throw ArtError.invalidResponse
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "query[term][is_public_domain]", value: "true"),
            URLQueryItem(name: "fields", value: "id,title,artist_display,image_id,thumbnail"),
            URLQueryItem(name: "limit", value: "50")
        ]

        guard let url = components.url else {
            print("[ArtService] Failed to create URL from components")
            throw ArtError.invalidResponse
        }

        print("[ArtService] Searching for keyword: '\(keyword)' at URL: \(url)")

        let request = NetworkRequest.get(url, headers: [:])

        do {
            let response: ArtSearchResponse = try await networkClient.perform(request)
            print("[ArtService] Got \(response.data.count) results for '\(keyword)'")

            // Log some sample data to understand structure
            if let first = response.data.first {
                print("[ArtService] Sample result - id: \(first.id), title: \(first.title ?? "nil"), imageId: \(first.imageId ?? "nil"), thumbnail: \(String(describing: first.thumbnail))")
            }

            // Filter to portraits with valid image IDs (or accept any with valid image if no thumbnail)
            let validArtworks = response.data.filter { artwork in
                // Must have an image ID
                guard let imageId = artwork.imageId, !imageId.isEmpty else {
                    return false
                }
                // If we have thumbnail data, prefer portraits; otherwise accept it
                if let thumbnail = artwork.thumbnail,
                   let width = thumbnail.width,
                   let height = thumbnail.height {
                    return height > width
                }
                // No thumbnail data - accept it anyway
                return true
            }

            print("[ArtService] After filtering: \(validArtworks.count) valid artworks")

            // Convert to domain models
            let artworks = validArtworks.compactMap { $0.toArtwork() }
            print("[ArtService] After conversion: \(artworks.count) artworks")

            // Return a random artwork if available
            let selected = artworks.randomElement()
            if let selected = selected {
                print("[ArtService] Selected: '\(selected.title)' by \(selected.artist)")
            }
            return selected
        } catch let error as NetworkError {
            print("[ArtService] NetworkError for '\(keyword)': \(error)")
            switch error {
            case .decodingError(let details):
                print("[ArtService] Decoding details: \(details)")
            case .httpError(let code, let data):
                if let data = data {
                    print("[ArtService] HTTP \(code): \(String(data: data, encoding: .utf8) ?? "no body")")
                } else {
                    print("[ArtService] HTTP \(code): no body")
                }
            default:
                break
            }
            throw error
        } catch {
            print("[ArtService] Other error for '\(keyword)': \(type(of: error)) - \(error)")
            throw error
        }
    }

    /// Gets and increments the keyword index for a condition.
    /// Used to try different keywords on refresh.
    private func nextKeywordIndex(for condition: WeatherCondition, totalKeywords: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }

        let currentIndex = keywordIndices[condition] ?? 0
        keywordIndices[condition] = (currentIndex + 1) % totalKeywords
        return currentIndex
    }
}
