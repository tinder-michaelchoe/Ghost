//
//  Artwork.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import Foundation

// MARK: - Artwork

/// Represents a piece of artwork from the Art Institute of Chicago.
public struct Artwork: Sendable, Identifiable, Equatable {
    public let id: Int
    public let title: String
    public let artist: String
    public let imageId: String

    public init(id: Int, title: String, artist: String, imageId: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.imageId = imageId
    }

    /// Constructs the IIIF image URL for this artwork.
    /// - Parameter size: The desired image width in pixels (height scales proportionally)
    /// - Returns: URL to the artwork image
    public func imageURL(size: Int = 843) -> URL? {
        URL(string: "https://www.artic.edu/iiif/2/\(imageId)/full/\(size),/0/default.jpg")
    }
}

// MARK: - Art Search Result

/// Result of an art search, including the artwork and the keyword that found it.
public struct ArtSearchResult: Sendable, Equatable {
    public let artwork: Artwork
    public let keyword: String

    public init(artwork: Artwork, keyword: String) {
        self.artwork = artwork
        self.keyword = keyword
    }
}

// MARK: - Art Error

/// Errors that can occur during art operations.
public enum ArtError: Error, Sendable {
    case noArtworkFound
    case networkError(String)
    case invalidResponse
    case imageLoadFailed

    public var localizedDescription: String {
        switch self {
        case .noArtworkFound:
            return "No artwork found for the current weather"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from art service"
        case .imageLoadFailed:
            return "Failed to load artwork image"
        }
    }
}
