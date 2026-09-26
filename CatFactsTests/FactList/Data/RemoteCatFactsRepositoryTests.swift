import XCTest
@testable import CatFacts

final class RemoteCatFactsRepositoryTests: XCTestCase {
    func testMapsResponseToDomainFacts() async throws {
        let json = """
        [{"_id": "1", "text": "Cats sleep a lot.", "status": {"verified": true, "sentCount": 3}, "createdAt": "2022-06-29T09:15:00 +0000"}]
        """
        let repository = RemoteCatFactsRepository(client: StubHTTPClient(.success(Data(json.utf8))))

        let facts = try await repository.fetchFacts()

        XCTAssertEqual(facts, [
            CatFact(id: "1", text: "Cats sleep a lot.", isVerified: true, createdAt: Date(timeIntervalSince1970: 1_656_494_100)),
        ])
    }

    func testKeepsFirstFactWhenIDsAreDuplicated() async throws {
        let json = """
        [
          {"_id": "1", "text": "First", "status": {"verified": false}, "createdAt": "2022-06-29T09:15:00 +0000"},
          {"_id": "1", "text": "Duplicate", "status": {"verified": false}, "createdAt": "2022-06-29T09:15:00 +0000"},
          {"_id": "2", "text": "Second", "status": {"verified": false}, "createdAt": "2022-06-29T09:15:00 +0000"}
        ]
        """
        let repository = RemoteCatFactsRepository(client: StubHTTPClient(.success(Data(json.utf8))))

        let facts = try await repository.fetchFacts()

        XCTAssertEqual(facts.map(\.text), ["First", "Second"])
    }

    func testMapsNetworkErrorsToDomainErrors() async {
        let cases: [(NetworkError, CatFactsError)] = [
            (.connection, .connection),
            (.badStatus(500), .server),
            (.invalidResponse, .invalidData),
            (.unknown, .unknown),
        ]

        for (networkError, expected) in cases {
            let repository = RemoteCatFactsRepository(client: StubHTTPClient(.failure(networkError)))
            do {
                _ = try await repository.fetchFacts()
                XCTFail("Expected \(expected) for \(networkError)")
            } catch {
                XCTAssertEqual(error as? CatFactsError, expected, "for \(networkError)")
            }
        }
    }
}

private struct StubHTTPClient: HTTPClient {
    let result: Result<Data, NetworkError>

    init(_ result: Result<Data, NetworkError>) {
        self.result = result
    }

    func get<Response: Decodable & Sendable>(_ url: URL, decoder: JSONDecoder) async throws -> Response {
        try decoder.decode(Response.self, from: result.get())
    }
}
