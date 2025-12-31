//
//  LocationService.swift
//  CoreContracts
//
//  Created by Claude on 12/31/25.
//

import Foundation

// MARK: - Location Service Protocol

/// Protocol for location-related services including GPS and geocoding.
public protocol LocationService: Sendable {

    /// Requests the user's current GPS location.
    /// - Returns: The user's current location as coordinates
    /// - Throws: LocationError if location cannot be determined
    func currentLocation() async throws -> LocationCoordinate

    /// Converts a zip code to geographic coordinates using geocoding.
    /// - Parameter zipCode: The zip code to geocode (US format)
    /// - Returns: The coordinates for the zip code center
    /// - Throws: LocationError if the zip code cannot be geocoded
    func coordinatesForZipCode(_ zipCode: String) async throws -> LocationCoordinate

    /// Reverse geocodes coordinates to get a place name.
    /// - Parameter coordinate: The coordinates to reverse geocode
    /// - Returns: A human-readable place name (city, state, etc.)
    /// - Throws: LocationError if reverse geocoding fails
    func placeName(for coordinate: LocationCoordinate) async throws -> String
}

// MARK: - Location Coordinate

/// Geographic coordinates.
public struct LocationCoordinate: Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Location Error

/// Errors that can occur during location operations.
public enum LocationError: Error, Sendable {
    /// Location services are not available or disabled
    case servicesUnavailable

    /// User denied location permission
    case permissionDenied

    /// Could not determine location
    case locationUnavailable

    /// Geocoding failed for the provided input
    case geocodingFailed(String)

    /// Invalid input (e.g., malformed zip code)
    case invalidInput(String)

    public var localizedDescription: String {
        switch self {
        case .servicesUnavailable:
            return "Location services are not available"
        case .permissionDenied:
            return "Location permission was denied"
        case .locationUnavailable:
            return "Could not determine your location"
        case .geocodingFailed(let reason):
            return "Geocoding failed: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        }
    }
}

// MARK: - Location Authorization Status

/// Authorization status for location services.
public enum LocationAuthorizationStatus: Sendable {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways
}
