import Foundation

final class RemoteCatFactsRepository: CatFactsRepository {
    static let endpoint = URL(string: "https://api.npoint.io/18962a8a5d00e62a8d2a")!

    private let client: HTTPClient
    private let url: URL

    init(client: HTTPClient, url: URL = RemoteCatFactsRepository.endpoint) {
        self.client = client
        self.url = url
    }

    func fetchFacts() async throws -> [CatFact] {
        let dtos: [CatFactDTO]
        do {
            dtos = try await client.get(url, decoder: CatFactDTO.decoder)
        } catch let error as NetworkError {
            throw CatFactsError(error)
        } catch {
            throw CatFactsError.unknown
        }

        // Duplicate IDs would crash the diffable data source, so keep the first occurrence.
        var seenIDs = Set<String>()
        return dtos
            .filter { seenIDs.insert($0.id).inserted }
            .map(\.domain)
    }
}

private extension CatFactsError {
    init(_ error: NetworkError) {
        switch error {
        case .connection: self = .connection
        case .badStatus: self = .server
        case .invalidResponse: self = .invalidData
        case .unknown: self = .unknown
        }
    }
}
