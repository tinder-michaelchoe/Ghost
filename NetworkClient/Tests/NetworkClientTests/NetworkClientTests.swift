//
//  NetworkClientTests.swift
//  NetworkClient
//
//  Created by mexicanpizza on 12/29/25.
//

import Foundation
import Testing
@testable import CoreContracts
@testable import NetworkClient

// MARK: - Network Request Tests

@Suite("NetworkRequest Tests")
struct NetworkRequestTests {

    @Test("GET request builds correctly")
    func getRequest() {
        let url = URL(string: "https://api.example.com/users")!
        let request = NetworkRequest.get(url, headers: ["Authorization": "Bearer token"])

        #expect(request.url == url)
        #expect(request.method == .get)
        #expect(request.headers["Authorization"] == "Bearer token")
        #expect(request.body == nil)
    }

    @Test("Request with query items")
    func queryItems() {
        let url = URL(string: "https://api.example.com/search")!
        let queryItems = [
            URLQueryItem(name: "q", value: "test"),
            URLQueryItem(name: "limit", value: "10")
        ]
        let request = NetworkRequest.get(url, queryItems: queryItems)

        #expect(request.queryItems.count == 2)
        #expect(request.queryItems[0].name == "q")
        #expect(request.queryItems[0].value == "test")
    }

    @Test("POST request with JSON body")
    func postWithJSON() throws {
        let url = URL(string: "https://api.example.com/users")!
        let body = TestUser(name: "John", email: "john@example.com")

        let request = try NetworkRequest.post(url, body: body)

        #expect(request.method == .post)
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.body != nil)

        // Verify body content
        let decoded = try JSONDecoder().decode(TestUser.self, from: request.body!)
        #expect(decoded.name == "John")
        #expect(decoded.email == "john@example.com")
    }

    @Test("Default timeout is 30 seconds")
    func defaultTimeout() {
        let url = URL(string: "https://api.example.com")!
        let request = NetworkRequest(url: url)

        #expect(request.timeoutInterval == 30)
    }

    @Test("Custom timeout")
    func customTimeout() {
        let url = URL(string: "https://api.example.com")!
        let request = NetworkRequest(url: url, timeoutInterval: 60)

        #expect(request.timeoutInterval == 60)
    }
}

// MARK: - Network Error Tests

@Suite("NetworkError Tests")
struct NetworkErrorTests {

    @Test("HTTP error equality")
    func httpErrorEquality() {
        let error1 = NetworkError.httpError(statusCode: 404, data: nil)
        let error2 = NetworkError.httpError(statusCode: 404, data: Data())
        let error3 = NetworkError.httpError(statusCode: 500, data: nil)

        #expect(error1 == error2) // Same status code
        #expect(error1 != error3) // Different status code
    }

    @Test("Error descriptions")
    func errorDescriptions() {
        #expect(NetworkError.invalidURL.localizedDescription == "Invalid URL")
        #expect(NetworkError.timeout.localizedDescription == "Request timed out")
        #expect(NetworkError.noConnection.localizedDescription == "No network connection")
        #expect(NetworkError.httpError(statusCode: 404, data: nil).localizedDescription == "HTTP error: 404")
    }
}

// MARK: - URLSession Network Client Tests

@Suite("URLSessionNetworkClient Tests")
struct URLSessionNetworkClientTests {

    @Test("JSON API factory creates configured client")
    func jsonAPIFactory() {
        let client = URLSessionNetworkClient.jsonAPI(baseHeaders: ["API-Key": "secret"])

        // Client should be created without errors
        #expect(client != nil)
    }

    @Test("Successful response decoding")
    func successfulDecoding() async throws {
        let mockSession = MockURLSession()
        let responseData = """
        {"name": "John", "email": "john@example.com"}
        """.data(using: .utf8)!

        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(session: mockSession)
        let request = NetworkRequest.get(URL(string: "https://api.example.com/user")!)

        let user: TestUser = try await client.perform(request)

        #expect(user.name == "John")
        #expect(user.email == "john@example.com")
    }

    @Test("HTTP error throws correct error")
    func httpError() async throws {
        let mockSession = MockURLSession()
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(session: mockSession)
        let request = NetworkRequest.get(URL(string: "https://api.example.com/missing")!)

        await #expect(throws: NetworkError.httpError(statusCode: 404, data: Data())) {
            let _: TestUser = try await client.perform(request)
        }
    }

    @Test("Decoding error provides helpful message")
    func decodingError() async throws {
        let mockSession = MockURLSession()
        let invalidJSON = """
        {"wrong_field": "value"}
        """.data(using: .utf8)!

        mockSession.mockData = invalidJSON
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(session: mockSession)
        let request = NetworkRequest.get(URL(string: "https://api.example.com/user")!)

        do {
            let _: TestUser = try await client.perform(request)
            Issue.record("Expected decoding error")
        } catch let error as NetworkError {
            if case .decodingError(let message) = error {
                #expect(message.contains("name"))
            } else {
                Issue.record("Expected decodingError, got \(error)")
            }
        }
    }

    @Test("Query items are appended to URL")
    func queryItemsAppended() async throws {
        let mockSession = MockURLSession()
        mockSession.mockData = "{}".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(session: mockSession)
        let request = NetworkRequest.get(
            URL(string: "https://api.example.com/search")!,
            queryItems: [URLQueryItem(name: "q", value: "test")]
        )

        let _ = try await client.performRaw(request)

        let capturedURL = mockSession.lastRequest?.url?.absoluteString
        #expect(capturedURL?.contains("q=test") == true)
    }

    @Test("Base headers are applied")
    func baseHeadersApplied() async throws {
        let mockSession = MockURLSession()
        mockSession.mockData = "{}".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(
            session: mockSession,
            baseHeaders: ["X-API-Key": "secret123"]
        )

        let request = NetworkRequest.get(URL(string: "https://api.example.com/data")!)
        let _ = try await client.performRaw(request)

        #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "X-API-Key") == "secret123")
    }

    @Test("Request headers override base headers")
    func requestHeadersOverride() async throws {
        let mockSession = MockURLSession()
        mockSession.mockData = "{}".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = URLSessionNetworkClient(
            session: mockSession,
            baseHeaders: ["Authorization": "Bearer base"]
        )

        let request = NetworkRequest.get(
            URL(string: "https://api.example.com/data")!,
            headers: ["Authorization": "Bearer override"]
        )
        let _ = try await client.performRaw(request)

        #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer override")
    }
}

// MARK: - Test Helpers

struct TestUser: Codable, Sendable, Equatable {
    let name: String
    let email: String
}

/// Mock URLSession for testing that conforms to URLSessionProtocol
final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request

        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw NetworkError.noData
        }

        return (data, response)
    }
}
