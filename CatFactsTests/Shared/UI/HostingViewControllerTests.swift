import SwiftUI
import XCTest
@testable import CatFacts

@MainActor
final class HostingViewControllerTests: XCTestCase {
    func testEmbedsSwiftUIViewAsChildFillingItsView() throws {
        let controller = HostingViewController(rootView: Greeting(name: "Tom"))

        controller.loadViewIfNeeded()

        let host = try XCTUnwrap(controller.children.first as? UIHostingController<Greeting>)
        XCTAssertIdentical(host.parent, controller)
        XCTAssertIdentical(host.view.superview, controller.view)
        XCTAssertEqual(host.view.backgroundColor, .clear)
        XCTAssertEqual(controller.view.backgroundColor, .systemBackground)
    }

    func testUpdatingRootViewUpdatesHostedView() throws {
        let controller = HostingViewController(rootView: Greeting(name: "Tom"))
        controller.loadViewIfNeeded()

        controller.rootView = Greeting(name: "Jerry")

        let host = try XCTUnwrap(controller.children.first as? UIHostingController<Greeting>)
        XCTAssertEqual(host.rootView, Greeting(name: "Jerry"))
    }
}

private struct Greeting: View, Equatable {
    let name: String

    var body: some View {
        Text("Hello, \(name)")
    }
}
