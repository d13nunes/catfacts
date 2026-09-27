import XCTest
@testable import CatFacts

final class UIImageUtilsTests: XCTestCase {
    func testResizedImageIsTheRequestedSizeInPoints() {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 32)).image { _ in }

        let resized = image.resized(to: 28)

        XCTAssertEqual(resized.size, CGSize(width: 28, height: 28))
    }
}
