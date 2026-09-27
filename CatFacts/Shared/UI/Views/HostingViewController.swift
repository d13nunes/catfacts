import SwiftUI
import UIKit

/// Wraps a SwiftUI view so UIKit can push, present or embed it as a child view controller.
/// The hosted view can reach this controller's navigation item through `\.hostingNavigationItem`, and the width of its
/// `readableContentGuide` through `\.readableContentWidth`.
final class HostingViewController<Content: View>: UIViewController {
    var rootView: Content {
        didSet { hostingController.rootView = hostedRoot }
    }

    private lazy var hostingController = UIHostingController(rootView: hostedRoot)
    private var readableContentWidth: CGFloat?

    private var hostedRoot: HostedRoot<Content> {
        HostedRoot(content: rootView, navigationItem: navigationItem, readableContentWidth: readableContentWidth)
    }

    init(rootView: Content) {
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let hostedView: UIView = hostingController.view
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The readable width changes with the screen size and the text size setting, so pass it on after each layout.
        let width = view.readableContentGuide.layoutFrame.width
        guard width != readableContentWidth else { return }
        readableContentWidth = width
        hostingController.rootView = hostedRoot
    }
}

/// The hosted content, with the wrapper's navigation item and readable width in its environment.
struct HostedRoot<Content: View>: View {
    let content: Content
    let navigationItem: UINavigationItem
    var readableContentWidth: CGFloat?

    var body: some View {
        content
            .environment(\.hostingNavigationItem, navigationItem)
            .environment(\.readableContentWidth, readableContentWidth)
    }
}

private struct HostingNavigationItemKey: EnvironmentKey {
    static var defaultValue: UINavigationItem? { nil }
}

private struct ReadableContentWidthKey: EnvironmentKey {
    static var defaultValue: CGFloat? { nil }
}

extension EnvironmentValues {
    /// The navigation item of the `HostingViewController` hosting this view, or nil outside one.
    var hostingNavigationItem: UINavigationItem? {
        get { self[HostingNavigationItemKey.self] }
        set { self[HostingNavigationItemKey.self] = newValue }
    }

    /// The width of the hosting `HostingViewController`'s `readableContentGuide`, or nil outside one.
    var readableContentWidth: CGFloat? {
        get { self[ReadableContentWidthKey.self] }
        set { self[ReadableContentWidthKey.self] = newValue }
    }
}

extension View {
    /// Caps the view's width at UIKit's readable content width, for comfortable line lengths, and centres it.
    /// SwiftUI has no `readableContentGuide`; outside a `HostingViewController` the width isn't capped.
    func readableContentWidth() -> some View {
        modifier(ReadableContentWidth())
    }
}

private struct ReadableContentWidth: ViewModifier {
    @Environment(\.readableContentWidth) private var width

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: width ?? .infinity)
            .frame(maxWidth: .infinity)
    }
}
