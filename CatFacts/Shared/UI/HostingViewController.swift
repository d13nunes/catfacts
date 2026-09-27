import SwiftUI
import UIKit

/// Wraps a SwiftUI view so UIKit can push, present or embed it as a child view controller.
/// The hosted view can reach this controller's navigation item through `\.hostingNavigationItem`.
final class HostingViewController<Content: View>: UIViewController {
    var rootView: Content {
        didSet { hostingController.rootView = hostedRoot }
    }

    private lazy var hostingController = UIHostingController(rootView: hostedRoot)

    private var hostedRoot: HostedRoot<Content> {
        HostedRoot(content: rootView, navigationItem: navigationItem)
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
}

/// The hosted content, with the wrapper's navigation item in its environment.
struct HostedRoot<Content: View>: View {
    let content: Content
    let navigationItem: UINavigationItem

    var body: some View {
        content.environment(\.hostingNavigationItem, navigationItem)
    }
}

private struct HostingNavigationItemKey: EnvironmentKey {
    static var defaultValue: UINavigationItem? { nil }
}

extension EnvironmentValues {
    /// The navigation item of the `HostingViewController` hosting this view, or nil outside one.
    var hostingNavigationItem: UINavigationItem? {
        get { self[HostingNavigationItemKey.self] }
        set { self[HostingNavigationItemKey.self] = newValue }
    }
}
