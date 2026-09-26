import Alamofire
import Foundation

final class AlamofireHTTPClient: HTTPClient {
    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func get<Response: Decodable & Sendable>(_ url: URL, decoder: JSONDecoder) async throws -> Response {
        do {
            return try await session.request(url)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .serializingDecodable(Response.self, automaticallyCancelling: true, decoder: decoder)
                .value
        } catch {
            throw NetworkError(error)
        }
    }
}

private extension NetworkError {
    init(_ error: Error) {
        switch error.asAFError {
        case .sessionTaskFailed(let underlying)?:
            self = (underlying as? URLError).map(NetworkError.init(urlError:)) ?? .unknown
        case .responseValidationFailed(reason: .unacceptableStatusCode(let code))?:
            self = .badStatus(code)
        case .responseValidationFailed?, .responseSerializationFailed?:
            self = .invalidResponse
        default:
            self = .unknown
        }
    }

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
