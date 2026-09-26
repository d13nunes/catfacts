import XCTest
@testable import CatFacts

@MainActor
final class FactsViewModelTests: XCTestCase {
    private let fact = CatFact(id: "1", text: "Cats purr.", isVerified: false, createdAt: Date(timeIntervalSince1970: 0))

    func testStartsInLoadingState() {
        let viewModel = FactsViewModel(repository: StubRepository())
        XCTAssertEqual(viewModel.state, .loading)
    }

    func testShowsFactsAfterSuccessfulLoad() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([fact]))
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
        viewModel.onStateChange = { states.append($0) }

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(states, [.loading, .failed(.server), .loading, .loaded([fact])])
    }

    func testFailedRefreshKeepsFactsAndReportsError() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact]), .failure(.connection)))
        var reportedError: CatFactsError?
        viewModel.onRefreshFailure = { reportedError = $0 }

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([fact]))
        XCTAssertEqual(reportedError, .connection)
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
