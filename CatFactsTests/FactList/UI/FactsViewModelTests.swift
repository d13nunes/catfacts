import Combine
import UIKit
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

        // A reload keeps the current screen until its result arrives, so there's no .loading in between.
        XCTAssertEqual(states, [.failed(.server), .loaded([item])])
    }

    func testRefreshShowsTheNewFacts() async {
        let newFact = makeFact("Kittens sleep a lot.")
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact]), .success([newFact])))

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(viewModel.searchResults.map(\.id), [newFact.id])
    }

    func testFailedRefreshShowsTheError() async {
        let viewModel = FactsViewModel(repository: StubRepository(.success([fact]), .failure(.connection)))

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(.connection))
    }

    func testReloadsWhenTheAppEntersTheForeground() async {
        let notificationCenter = NotificationCenter()
        let newFact = makeFact("Kittens sleep a lot.")
        let viewModel = FactsViewModel(
            repository: StubRepository(.success([fact]), .success([newFact])),
            notificationCenter: notificationCenter
        )
        await viewModel.load()

        await post(UIApplication.willEnterForegroundNotification, on: notificationCenter, reloading: viewModel)

        XCTAssertEqual(viewModel.searchResults.map(\.id), [newFact.id])
    }

    func testForegroundReloadRecoversFromAnError() async {
        let notificationCenter = NotificationCenter()
        let viewModel = FactsViewModel(
            repository: StubRepository(.failure(.connection), .success([fact])),
            notificationCenter: notificationCenter
        )
        await viewModel.load()

        await post(UIApplication.willEnterForegroundNotification, on: notificationCenter, reloading: viewModel)

        XCTAssertEqual(viewModel.state, .loaded([item]))
    }

    func testForegroundReloadMarksNewFactsAgainstTheCurrentDate() async {
        let notificationCenter = NotificationCenter()
        let fact = makeFact("Cats purr.", createdAt: now)
        var currentDate = now
        let viewModel = FactsViewModel(
            repository: StubRepository(.success([fact]), .success([fact])),
            now: { currentDate },
            notificationCenter: notificationCenter
        )
        await viewModel.load()
        XCTAssertEqual(viewModel.searchResults.map(\.isNew), [true])

        currentDate = Calendar.current.date(byAdding: .day, value: viewModel.isNewThresholdInDays + 1, to: now)!
        await post(UIApplication.willEnterForegroundNotification, on: notificationCenter, reloading: viewModel)

        XCTAssertEqual(viewModel.searchResults.map(\.isNew), [false])
    }

    func testIgnoresOtherAppLifecycleNotifications() async {
        let notificationCenter = NotificationCenter()
        let viewModel = FactsViewModel(
            repository: StubRepository(.success([fact]), .success([])),
            notificationCenter: notificationCenter
        )
        await viewModel.load()

        for name in [
            UIApplication.didBecomeActiveNotification,
            UIApplication.willResignActiveNotification,
            UIApplication.didEnterBackgroundNotification,
        ] {
            await post(name, on: notificationCenter, reloading: viewModel, expectsReload: false)
        }

        XCTAssertEqual(viewModel.state, .loaded([item]))
    }

    func testForegroundObserverDoesNotKeepTheViewModelAlive() {
        let notificationCenter = NotificationCenter()
        var viewModel: FactsViewModel? = FactsViewModel(repository: StubRepository(), notificationCenter: notificationCenter)
        weak let weakViewModel = viewModel

        viewModel = nil

        XCTAssertNil(weakViewModel)
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

    /// Posts `name` on `notificationCenter` and waits for `viewModel` to publish its reloaded state.
    /// With `expectsReload` false, waits briefly and fails if the view model reloads.
    private func post(
        _ name: Notification.Name,
        on notificationCenter: NotificationCenter,
        reloading viewModel: FactsViewModel,
        expectsReload: Bool = true
    ) async {
        let reloaded = expectation(description: "\(viewModel) reloads after \(name.rawValue)")
        reloaded.isInverted = !expectsReload
        // dropFirst skips the value $state emits on subscribe.
        let subscription = viewModel.$state.dropFirst().sink { _ in reloaded.fulfill() }
        defer { subscription.cancel() }

        notificationCenter.post(name: name, object: nil)

        await fulfillment(of: [reloaded], timeout: expectsReload ? 1 : 0.1)
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
