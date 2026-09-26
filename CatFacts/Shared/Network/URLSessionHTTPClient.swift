import Foundation

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // URLSession runs the request on its own queues; @concurrent keeps the checks and JSON decoding off the
    // caller's actor too, even when the caller is the main actor.
    @concurrent
    func get<Response: Decodable & Sendable>(_ url: URL, decoder: JSONDecoder) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let error as URLError {
            throw NetworkError(urlError: error)
        } catch {
            throw NetworkError.unknown
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.badStatus(httpResponse.statusCode)
        }
        guard httpResponse.mimeType == "application/json" else {
            throw NetworkError.invalidResponse
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.invalidResponse
        }
    }
}

private extension NetworkError {
    init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut,
             .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
             .dataNotAllowed, .internationalRoamingOff:
            self = .connection
        default:
            self = .unknown
        }
    }
}
