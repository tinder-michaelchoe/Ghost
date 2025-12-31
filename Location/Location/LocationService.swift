//
//  LocationService.swift
//  Location
//
//  Created by Claude on 12/31/25.
//

import CoreContracts
import CoreLocation
import Foundation

// MARK: - Core Location Service

/// Implementation of LocationService using Core Location framework.
public final class CoreLocationService: NSObject, LocationService, @unchecked Sendable {

    // MARK: - Properties

    private let locationManager: CLLocationManager
    private let geocoder: CLGeocoder

    private var locationContinuation: CheckedContinuation<LocationCoordinate, Error>?
    private let lock = NSLock()

    // MARK: - Init

    public override init() {
        self.locationManager = CLLocationManager()
        self.geocoder = CLGeocoder()
        super.init()

        // CLLocationManager must be set up on main thread
        if Thread.isMainThread {
            setupLocationManager()
        } else {
            DispatchQueue.main.sync {
                self.setupLocationManager()
            }
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - LocationService

    public func currentLocation() async throws -> LocationCoordinate {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.locationContinuation = continuation
            lock.unlock()

            DispatchQueue.main.async {
                let status = self.locationManager.authorizationStatus

                switch status {
                case .notDetermined:
                    self.locationManager.requestWhenInUseAuthorization()

                case .restricted, .denied:
                    self.resumeWithError(.permissionDenied)

                case .authorizedWhenInUse, .authorizedAlways:
                    self.locationManager.requestLocation()

                @unknown default:
                    self.resumeWithError(.servicesUnavailable)
                }
            }
        }
    }

    public func coordinatesForZipCode(_ zipCode: String) async throws -> LocationCoordinate {
        // Validate zip code format (US: 5 digits or 5+4)
        let cleanedZip = zipCode.trimmingCharacters(in: .whitespaces)
        guard cleanedZip.count >= 5,
              cleanedZip.prefix(5).allSatisfy({ $0.isNumber }) else {
            throw LocationError.invalidInput("Invalid zip code format")
        }

        // Use CLGeocoder to convert zip code to coordinates
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.geocodeAddressString(cleanedZip)
        } catch {
            throw LocationError.geocodingFailed("Could not find location for zip code: \(cleanedZip)")
        }

        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw LocationError.geocodingFailed("No location found for zip code: \(cleanedZip)")
        }

        return LocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    public func placeName(for coordinate: LocationCoordinate) async throws -> String {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.reverseGeocodeLocation(location)
        } catch {
            throw LocationError.geocodingFailed("Could not determine place name")
        }

        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed("No place found at coordinates")
        }

        // Build a readable place name
        if let city = placemark.locality, let state = placemark.administrativeArea {
            return "\(city), \(state)"
        } else if let city = placemark.locality {
            return city
        } else if let area = placemark.administrativeArea {
            return area
        } else if let name = placemark.name {
            return name
        }

        throw LocationError.geocodingFailed("Could not determine place name")
    }

    // MARK: - Private

    private func resumeWithLocation(_ coordinate: LocationCoordinate) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()

        continuation?.resume(returning: coordinate)
    }

    private func resumeWithError(_ error: LocationError) {
        lock.lock()
        let continuation = locationContinuation
        locationContinuation = nil
        lock.unlock()

        continuation?.resume(throwing: error)
    }
}

// MARK: - CLLocationManagerDelegate

extension CoreLocationService: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        resumeWithLocation(LocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                resumeWithError(.permissionDenied)
            case .locationUnknown:
                resumeWithError(.locationUnavailable)
            default:
                resumeWithError(.servicesUnavailable)
            }
        } else {
            resumeWithError(.locationUnavailable)
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        // Only act if we have a pending continuation
        lock.lock()
        let hasContinuation = locationContinuation != nil
        lock.unlock()

        guard hasContinuation else { return }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, request location
            manager.requestLocation()

        case .denied, .restricted:
            resumeWithError(.permissionDenied)

        case .notDetermined:
            // Still waiting for user to decide
            break

        @unknown default:
            break
        }
    }
}
