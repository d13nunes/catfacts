import XCTest
@testable import CatFacts

@MainActor
final class AppNavigationControllerTests: XCTestCase {

    func testBeforeLiquidGlassTheBarIsSolidWithALineInEveryState() throws {
        guard #unavailable(iOS 26) else { throw XCTSkip("From iOS 26 the bar keeps the system's Liquid Glass look.") }
        let controller = AppNavigationController(rootViewController: UIViewController())

        controller.loadViewIfNeeded()

        let bar = controller.navigationBar
        let appearances = [bar.standardAppearance, bar.compactAppearance, bar.scrollEdgeAppearance, bar.compactScrollEdgeAppearance]
        for appearance in appearances {
            XCTAssertEqual(appearance?.backgroundColor, .systemBackground)
            XCTAssertNotNil(appearance?.shadowImage)
        }
    }

    func testFromLiquidGlassTheBarKeepsTheSystemAppearance() throws {
        guard #available(iOS 26, *) else { throw XCTSkip("Before iOS 26 the bar is made solid.") }
        let controller = AppNavigationController(rootViewController: UIViewController())

        controller.loadViewIfNeeded()

        XCTAssertNil(controller.navigationBar.scrollEdgeAppearance)
        XCTAssertNil(controller.navigationBar.compactAppearance)
    }
}
