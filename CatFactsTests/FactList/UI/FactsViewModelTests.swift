import Combine
import XCTest
@testable import CatFacts

@MainActor
final class FactsViewModelTests: XCTestCase {
    private let fact = CatFact(id: "1", text: "Cats purr.", isVerified: false, createdAt: Date(timeIntervalSince1970: 0))
    private let item = FactItem(id: "1", text: "Cats purr.", isVerified: false, isNew: false)
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testStartsInLoadingState() {
        let viewModel = FactsViewModel(repository: StubRepository())
        XCTAssertEqual(viewModel.state, .loading)
    }

    func testShowsFactsAfterSuccessfulLoad() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([item]))
    }

    func testMarksVerifiedFacts() async {
        let verified = makeFact("Cats purr.", isVerified: true)
        let viewModel = FactsViewModel(repository: StubRepository(.success([verified, makeFact("Cats nap.")])))

        await viewModel.load()

        XCTAssertEqual(viewModel.searchResults.map(\.isVerified), [true, false])
    }

    func testMarksFactsFromTheLast90DaysAsNew() async {
        let facts = [89, 90, 91].map { daysAgo in
            makeFact("\(daysAgo) days old", createdAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!)
        }
        let viewModel = FactsViewModel(repository: StubRepository(.success(facts)), now: { [now] in now })

        await viewModel.load()

        XCTAssertEqual(viewModel.searchResults.map(\.isNew), [true, true, false])
    }

    func testShowsEmptyStateWhenThereAreNoFacts() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testShowsErrorWhenFirstLoadFails() async {
        let viewModel = FactsViewModel(repository: StubRepository(.failure(.connection)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(.connection))
    }

    func testRetryAfterFailureShowsFacts() async {
        let viewModel = FactsViewModel(repository: StubRepository(.failure(.server), .success([fact])))
        var states: [FactsViewModel.State] = []
        // dropFirst skips the value $state emits on subscribe.
        let subscription = viewModel.$state.dropFirst().sink { states.append($0) }
        defer { subscription.cancel() }

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(states, [.loading, .failed(.server), .loading, .loaded([item])])
    }

    func testFailedRefreshKeepsFactsAndReportsError() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact]), .failure(.connection)))

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([item]))
        XCTAssertEqual(viewModel.refreshError, .connection)
    }

    func testBlankQueryShowsAllFacts() async {
        let facts = [makeFact("Cats purr."), makeFact("Kittens sleep a lot.")]
        let viewModel = FactsViewModel(repository: StubRepository(.success(facts)))
        await viewModel.load()

        viewModel.query = "  "

        XCTAssertEqual(viewModel.searchResults.map(\.id), facts.map(\.id))
    }

    func testSearchIgnoresCaseAndDiacritics() async {
        let purr = makeFact("Cats purr.")
        let cafe = makeFact("Café cats nap in the sun.")
        let viewModel = FactsViewModel(repository: StubRepository(.success([purr, cafe, makeFact("Kittens sleep.")])))
        await viewModel.load()

        viewModel.query = "PURR"
        XCTAssertEqual(viewModel.searchResults.map(\.id), [purr.id])

        viewModel.query = "cafe"
        XCTAssertEqual(viewModel.searchResults.map(\.id), [cafe.id])
    }

    func testSearchMatchesFactsContainingEveryWord() async {
        let kittens = makeFact("Kittens sleep a lot.")
        let viewModel = FactsViewModel(repository: StubRepository(.success([makeFact("Cats sleep."), kittens])))
        await viewModel.load()

        viewModel.query = " lot  sleep "
        XCTAssertEqual(viewModel.searchResults.map(\.id), [kittens.id])

        viewModel.query = "kittens purr"
        XCTAssertEqual(viewModel.searchResults.map(\.id), [])
    }

    private func makeFact(
        _ text: String,
        isVerified: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> CatFact {
        CatFact(id: text, text: text, isVerified: isVerified, createdAt: createdAt)
    }
}

private final class StubRepository: CatFactsRepository, @unchecked Sendable {
    private var results: [Result<[CatFact], CatFactsError>]

    init(_ results: Result<[CatFact], CatFactsError>...) {
        self.results = results
    }

    func fetchFacts() async throws -> [CatFact] {
        try results.removeFirst().get()
    }
}
