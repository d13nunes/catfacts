import Foundation

@MainActor
final class FactsViewModel {
    enum State: Equatable {
        case loading
        case loaded([CatFact])
        case empty
        case failed(CatFactsError)
    }

    var onStateChange: ((State) -> Void)?
    /// Called instead of replacing loaded facts with an error when a refresh fails.
    var onRefreshFailure: ((CatFactsError) -> Void)?

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    private let repository: CatFactsRepository
    private var isLoading = false

    init(repository: CatFactsRepository) {
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let isRefresh = hasFacts
        if !isRefresh {
            state = .loading
        }

        do {
            let facts = try await repository.fetchFacts()
            guard !Task.isCancelled else { return }
            state = facts.isEmpty ? .empty : .loaded(facts)
        } catch {
            guard !Task.isCancelled else { return }
            let error = error as? CatFactsError ?? .unknown
            if isRefresh {
                onRefreshFailure?(error)
            } else {
                state = .failed(error)
            }
        }
    }

    private var hasFacts: Bool {
        if case .loaded = state { return true }
        return false
    }
}
