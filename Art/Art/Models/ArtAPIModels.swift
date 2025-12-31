//
//  ArtAPIModels.swift
//  Art
//
//  Created by Claude on 12/31/25.
//

import Foundation

// MARK: - Search Response

/// Response from the Art Institute of Chicago search API.
struct ArtSearchResponse: Decodable {
    let data: [ArtworkData]
}

/// Individual artwork data from search results.
/// Note: The NetworkClient uses .convertFromSnakeCase, so we don't need CodingKeys
struct ArtworkData: Decodable {
    let id: Int
    let title: String?
    let artistDisplay: String?
    let imageId: String?
    let thumbnail: ThumbnailData?

    /// Whether this artwork is portrait orientation (height > width).
    var isPortrait: Bool {
        guard let thumbnail = thumbnail,
              let width = thumbnail.width,
              let height = thumbnail.height else {
            return false
        }
        return height > width
    }

    /// Converts to domain model if all required fields are present.
    func toArtwork() -> Artwork? {
        guard let title = title,
              let imageId = imageId,
              !imageId.isEmpty else {
            return nil
        }
        return Artwork(
            id: id,
            title: title,
            artist: artistDisplay ?? "Unknown Artist",
            imageId: imageId
        )
    }
}

/// Thumbnail dimensions for determining orientation.
struct ThumbnailData: Decodable {
    let width: Int?
    let height: Int?
}
