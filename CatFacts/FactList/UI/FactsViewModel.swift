import Combine
import Foundation

struct FactItem: Equatable, Identifiable {
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
    @Published private(set) var refreshError: CatFactsError? = nil
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
        refreshError = nil

        let isRefresh = hasFacts
        if !isRefresh {
            state = .loading
        }

        do {
            let facts = try await repository.fetchFacts()
            guard !Task.isCancelled else { return }
            state = facts.isEmpty ? .empty : .loaded(facts.map {
                FactItem(id: $0.id, text: $0.text, isVerified: $0.isVerified, isNew: isNew($0.createdAt))
            })
        } catch {
            guard !Task.isCancelled else { return }
            let error = error as? CatFactsError ?? .unknown
            if isRefresh {
                refreshError = error
            } else {
                state = .failed(error)
            }
        }
    }

    /// Whether `date` falls within the last `isNewThresholdInDays` days.
    private func isNew(_ date: Date) -> Bool {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -isNewThresholdInDays, to: now()) else {
            return false
        }
        return date >= cutoff
    }

    private var hasFacts: Bool {
        if case .loaded = state { return true }
        return false
    }
}
