import Foundation

protocol HTTPClient: Sendable {
    /// Throws `NetworkError`.
    func get<Response: Decodable & Sendable>(_ url: URL, decoder: JSONDecoder) async throws -> Response
}

enum NetworkError: Error, Equatable {
    case connection
    case badStatus(Int)
    case invalidResponse
    case unknown
}
