//
//  NetworkClient.swift
//  CoreContracts
//
//  Created by mexicanpizza on 12/29/25.
//

import Foundation

// MARK: - Network Client Protocol

/// Protocol for making REST API requests
public protocol NetworkClient: Sendable {

    /// Performs a network request and decodes the response
    /// - Parameters:
    ///   - request: The request to perform
    /// - Returns: The decoded response
    func perform<T: Decodable & Sendable>(_ request: NetworkRequest) async throws -> T

    /// Performs a network request and returns raw data
    /// - Parameter request: The request to perform
    /// - Returns: The response data and URL response
    func performRaw(_ request: NetworkRequest) async throws -> (Data, URLResponse)
}

// MARK: - Network Request

/// Represents an HTTP request
public struct NetworkRequest: Sendable {

    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?
    public let queryItems: [URLQueryItem]
    public let timeoutInterval: TimeInterval

    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        timeoutInterval: TimeInterval = 30
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
        self.timeoutInterval = timeoutInterval
    }

    /// Convenience initializer for JSON body
    public init<T: Encodable>(
        url: URL,
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        jsonBody: T,
        queryItems: [URLQueryItem] = [],
        timeoutInterval: TimeInterval = 30,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        var allHeaders = headers
        allHeaders["Content-Type"] = "application/json"

        self.url = url
        self.method = method
        self.headers = allHeaders
        self.body = try encoder.encode(jsonBody)
        self.queryItems = queryItems
        self.timeoutInterval = timeoutInterval
    }
}

// MARK: - HTTP Method

/// HTTP request methods
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Error

/// Errors that can occur during network operations
public enum NetworkError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(String)
    case noData
    case timeout
    case noConnection
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .noData:
            return "No data received"
        case .timeout:
            return "Request timed out"
        case .noConnection:
            return "No network connection"
        case .unknown(let message):
            return message
        }
    }

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.noData, .noData),
             (.timeout, .timeout),
             (.noConnection, .noConnection):
            return true
        case (.httpError(let lCode, _), .httpError(let rCode, _)):
            return lCode == rCode
        case (.decodingError(let lMsg), .decodingError(let rMsg)):
            return lMsg == rMsg
        case (.unknown(let lMsg), .unknown(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Network Response

/// Wrapper for network responses with metadata
public struct NetworkResponse<T: Sendable>: Sendable {
    public let data: T
    public let statusCode: Int
    public let headers: [String: String]

    public init(data: T, statusCode: Int, headers: [String: String]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}

// MARK: - URL Session Protocol

/// Protocol abstracting URLSession's data fetching capability for testability.
public protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Request Builder Extension

public extension NetworkRequest {

    /// Creates a GET request
    static func get(
        _ url: URL,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = []
    ) -> NetworkRequest {
        NetworkRequest(url: url, method: .get, headers: headers, queryItems: queryItems)
    }

    /// Creates a POST request with JSON body
    static func post<T: Encodable>(
        _ url: URL,
        body: T,
        headers: [String: String] = [:]
    ) throws -> NetworkRequest {
        try NetworkRequest(url: url, method: .post, headers: headers, jsonBody: body)
    }

    /// Creates a PUT request with JSON body
    static func put<T: Encodable>(
        _ url: URL,
        body: T,
        headers: [String: String] = [:]
    ) throws -> NetworkRequest {
        try NetworkRequest(url: url, method: .put, headers: headers, jsonBody: body)
    }

    /// Creates a DELETE request
    static func delete(
        _ url: URL,
        headers: [String: String] = [:]
    ) -> NetworkRequest {
        NetworkRequest(url: url, method: .delete, headers: headers)
    }
}
