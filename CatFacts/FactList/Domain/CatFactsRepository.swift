protocol CatFactsRepository: Sendable {
    /// Throws `CatFactsError`.
    func fetchFacts() async throws -> [CatFact]
}

enum CatFactsError: Error, Equatable {
    case connection
    case server
    case invalidData
    case unknown
}
