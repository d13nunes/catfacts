import UIKit

/// The app's navigation controller: large titles and, before Liquid Glass (iOS 26), a solid bar with a solid line along
/// its bottom edge.
final class AppNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = true
        if #unavailable(iOS 26) {
            applySolidAppearance()
        }
    }

    private func applySolidAppearance() {
        // An appearance's background also fills the status bar area, which navigationBar.backgroundColor doesn't.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        // A template shadow image is tinted with shadowColor, so the line follows light and dark mode.
        appearance.shadowImage = Self.makeLineImage(height: 1)
        appearance.shadowColor = .separator
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        // With large titles the bar uses the scroll-edge appearances at the top of the list; they're transparent by default.
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
    }

    /// A solid line `height` points tall, which the bar stretches to its width. Replaces the default hairline.
    private static func makeLineImage(height: CGFloat) -> UIImage {
        let size = CGSize(width: 1, height: height)
        return UIGraphicsImageRenderer(size: size).image { context in
            context.fill(CGRect(origin: .zero, size: size))
        }
        .withRenderingMode(.alwaysTemplate)
    }
}
