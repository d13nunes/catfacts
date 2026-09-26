import SwiftUI
import UIKit

/// Wraps a SwiftUI view so UIKit can push, present or embed it as a child view controller.
/// The background is `.systemBackground`; set `view.backgroundColor = .clear` to show what's behind it.
final class HostingViewController<Content: View>: UIViewController {
    var rootView: Content {
        get { hostingController.rootView }
        set { hostingController.rootView = newValue }
    }

    private let hostingController: UIHostingController<Content>

    init(rootView: Content) {
        hostingController = UIHostingController(rootView: rootView)
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
