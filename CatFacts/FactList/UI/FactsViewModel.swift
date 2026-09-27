import Combine
import Foundation

struct FactItem: Equatable, Identifiable, Sendable {
    let id: String
    let text: String
    let isVerified: Bool
    let isNew: Bool
}

@MainActor
final class FactsViewModel: ObservableObject {
  
    enum State: Equatable {
        case loading
        case loaded([FactItem])
        case empty
        case failed(CatFactsError)
    }

    @Published private(set) var state: State = .loading
    @Published var query = ""

    let isNewThresholdInDays: Int

    /// Loaded facts containing every word in `query`, ignoring case and diacritics. All loaded facts when the query is blank.
    var searchResults: [FactItem] {
        guard case .loaded(let facts) = state else { return [] }
        let terms = query.split(whereSeparator: \.isWhitespace)
        guard !terms.isEmpty else { return facts }
        return facts.filter { fact in
            terms.allSatisfy { fact.text.localizedStandardContains($0) }
        }
    }

    private let repository: CatFactsRepository
    private let now: () -> Date
    private var isLoading = false

    init(repository: CatFactsRepository, isNewThresholdInDays: Int = 90, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.isNewThresholdInDays = isNewThresholdInDays
        self.now = now
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            // A fact is new when it was created within the last `isNewThresholdInDays` days.
            let newSince = Calendar.current.date(byAdding: .day, value: -isNewThresholdInDays, to: now())
            let items = try await Self.fetchItems(from: repository, newSince: newSince)
            guard !Task.isCancelled else { return }
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            guard !Task.isCancelled else { return }
            let error = error as? CatFactsError ?? .unknown
            state = .failed(error)
        }
    }

    /// Fetches and maps the facts off the main actor, so only the resulting state change runs on it.
    @concurrent
    private nonisolated static func fetchItems(
        from repository: CatFactsRepository,
        newSince: Date?
    ) async throws -> [FactItem] {
        try await repository.fetchFacts().map { fact in
            FactItem(
                id: fact.id,
                text: fact.text,
                isVerified: fact.isVerified,
                isNew: newSince.map { fact.createdAt >= $0 } ?? false
            )
        }
    }
}
