import SwiftUI
import XCTest
@testable import CatFacts

@MainActor
final class HostingViewControllerTests: XCTestCase {
    func testEmbedsSwiftUIViewAsChildFillingItsView() throws {
        let controller = HostingViewController(rootView: Greeting(name: "Tom"))

        controller.loadViewIfNeeded()

        let host = try XCTUnwrap(controller.children.first as? UIHostingController<HostedRoot<Greeting>>)
        XCTAssertIdentical(host.parent, controller)
        XCTAssertIdentical(host.view.superview, controller.view)
        XCTAssertEqual(host.view.backgroundColor, .clear)
        XCTAssertEqual(controller.view.backgroundColor, .systemBackground)
    }

    func testUpdatingRootViewUpdatesHostedView() throws {
        let controller = HostingViewController(rootView: Greeting(name: "Tom"))
        controller.loadViewIfNeeded()

        controller.rootView = Greeting(name: "Jerry")

        let host = try XCTUnwrap(controller.children.first as? UIHostingController<HostedRoot<Greeting>>)
        XCTAssertEqual(host.rootView.content, Greeting(name: "Jerry"))
        XCTAssertIdentical(host.rootView.navigationItem, controller.navigationItem)
    }

    func testNavigationSearchBarWritesSearchTextIntoBinding() throws {
        var query = ""
        let controller = HostingViewController(
            rootView: Greeting(name: "Tom").navigationSearchBar(
                text: Binding(get: { query }, set: { query = $0 }),
                placeholder: "Search"
            )
        )
        let window = try makeWindow(showing: UINavigationController(rootViewController: controller))
        defer { window.isHidden = true }

        // The modifier installs the search controller when the SwiftUI view appears.
        waitUntil { controller.navigationItem.searchController != nil }
        let searchController = try XCTUnwrap(controller.navigationItem.searchController)
        searchController.searchBar.text = "whiskers"
        searchController.searchResultsUpdater?.updateSearchResults(for: searchController)

        XCTAssertEqual(searchController.searchBar.placeholder, "Search")
        XCTAssertEqual(query, "whiskers")
    }

    func testNavigationItemTitleSetsAndUpdatesTheTitle() throws {
        let controller = HostingViewController(rootView: Greeting(name: "Tom").navigationItemTitle("Facts"))
        let window = try makeWindow(showing: UINavigationController(rootViewController: controller))
        defer { window.isHidden = true }

        waitUntil { controller.navigationItem.title != nil }
        XCTAssertEqual(controller.navigationItem.title, "Facts")

        controller.rootView = Greeting(name: "Tom").navigationItemTitle("Cat Facts")
        waitUntil { controller.navigationItem.title == "Cat Facts" }
        XCTAssertEqual(controller.navigationItem.title, "Cat Facts")
    }

    /// Runs the main run loop until `condition` holds or two seconds pass, so SwiftUI can apply its updates.
    private func waitUntil(_ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(2)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    private func makeWindow(showing rootViewController: UIViewController) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        return window
    }
}

private struct Greeting: View, Equatable {
    let name: String

    var body: some View {
        Text("Hello, \(name)")
    }
}
