//
//  NetworkClient.swift
//  NetworkClient
//
//  Created by mexicanpizza on 12/29/25.
//

import CoreContracts
import Foundation

// MARK: - URL Session Network Client

/// Default implementation of NetworkRequestPerforming using URLSession
public final class URLSessionNetworkClient: NetworkRequestPerforming, @unchecked Sendable {

    // MARK: - Properties

    private let session: URLSessionProtocol
    private let decoder: JSONDecoder
    private let baseHeaders: [String: String]

    // MARK: - Init

    public init(
        session: URLSessionProtocol = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        baseHeaders: [String: String] = [:]
    ) {
        self.session = session
        self.decoder = decoder
        self.baseHeaders = baseHeaders
    }

    /// Creates a client with common JSON API configuration
    public static func jsonAPI(baseHeaders: [String: String] = [:]) -> URLSessionNetworkClient {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        var headers = baseHeaders
        headers["Accept"] = "application/json"

        return URLSessionNetworkClient(decoder: decoder, baseHeaders: headers)
    }

    // MARK: - NetworkClient

    public func perform<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T {
        let (data, response) = try await performRaw(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decodingError(describeDecodingError(error))
        }
    }

    public func performRaw(_ request: NetworkRequest) async throws -> (Data, URLResponse) {
        let urlRequest = try buildURLRequest(from: request)

        do {
            return try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    private func buildURLRequest(from request: NetworkRequest) throws -> URLRequest {
        var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: true)

        if !request.queryItems.isEmpty {
            let existingItems = urlComponents?.queryItems ?? []
            urlComponents?.queryItems = existingItems + request.queryItems
        }

        guard let finalURL = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval

        // Apply base headers first, then request-specific headers (allowing overrides)
        for (key, value) in baseHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .badURL:
            return .invalidURL
        default:
            return .unknown(error.localizedDescription)
        }
    }

    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Missing value for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Data corrupted: \(context.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }
}

