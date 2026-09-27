import Combine
import Foundation
import UIKit

struct FactItem: Equatable, Sendable {
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
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: CatFactsRepository,
        isNewThresholdInDays: Int = AppConstants.newFactThresholdInDays,
        now: @escaping () -> Date = Date.init,
        notificationCenter: NotificationCenter = .default
    ) {
        self.repository = repository
        self.isNewThresholdInDays = isNewThresholdInDays
        self.now = now
        // Reload when the app comes back to the foreground, so the facts and "new" badges aren't stale.
        notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { await self?.load(keepingFactsOnFailure: true) }
            }
            .store(in: &cancellables)
    }

    func load() async {
        await load(keepingFactsOnFailure: false)
    }

    /// Reloads the facts for pull to refresh. If the reload fails, the facts already on screen stay.
    func refresh() async {
        await load(keepingFactsOnFailure: true)
    }

    private func load(keepingFactsOnFailure: Bool) async {
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
            if keepingFactsOnFailure, case .loaded = state { return }
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
  
  let emptyContent = StatusView.Content(
      symbolName: "tray",
      title: "No cat facts yet",
      message: "Check back later for new facts.",
      actionTitle: "Refresh"
  )

  func noResultsContent(for query: String) -> StatusView.Content {
      let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
      return StatusView.Content(
          symbolName: "magnifyingglass",
          title: "No results",
          message: "No cat facts match “\(query)”.",
          actionTitle: nil
      )
  }

  func failureContent(_ error: CatFactsError) -> StatusView.Content {
      let tryAgain = "Try Again"
      switch error {
      case .connection:
          return StatusView.Content(
              symbolName: "wifi.slash",
              title: "No connection",
              message: "Check your internet connection and try again.",
              actionTitle: tryAgain
          )
      case .server:
          return StatusView.Content(
              symbolName: "exclamationmark.icloud",
              title: "Service unavailable",
              message: "Cat facts can't be loaded right now. Please try again later.",
              actionTitle: tryAgain
          )
      case .invalidData:
          return StatusView.Content(
              symbolName: "exclamationmark.triangle",
              title: "Something went wrong",
              message: "We received cat facts we couldn't read. Please try again later.",
              actionTitle: tryAgain
          )
      case .unknown:
          return StatusView.Content(
              symbolName: "exclamationmark.triangle",
              title: "Something went wrong",
              message: "Please try again.",
              actionTitle: tryAgain
          )
      }
  }
}
