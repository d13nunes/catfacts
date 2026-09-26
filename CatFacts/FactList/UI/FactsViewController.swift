// import Combine
// import SwiftUI
// import UIKit

// final class FactsViewController: UIViewController {
//     private enum Section {
//         case main
//     }

//     private let viewModel: FactsViewModel
//     private var loadTask: Task<Void, Never>?
//     private var cancellables = Set<AnyCancellable>()

//     private let refreshControl = UIRefreshControl()
//     private let loadingIndicator = UIActivityIndicatorView(style: .large)
//     private let statusController = HostingViewController(rootView: StatusView(content: .empty))
//     private lazy var collectionView: UICollectionView = {
//         let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
//         let collectionView = UICollectionView(
//             frame: .zero,
//             collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration)
//         )
//         collectionView.allowsSelection = false
//         collectionView.refreshControl = refreshControl
//         return collectionView
//     }()
//     private lazy var dataSource = makeDataSource()

//     init(viewModel: FactsViewModel) {
//         self.viewModel = viewModel
//         super.init(nibName: nil, bundle: nil)
//     }

//     @available(*, unavailable)
//     required init?(coder: NSCoder) {
//         fatalError("init(coder:) has not been implemented")
//     }

//     deinit {
//         // The subscriptions in `cancellables` cancel themselves when released; the load task doesn't.
//         loadTask?.cancel()
//     }

//     override func viewDidLoad() {
//         super.viewDidLoad()
//         title = String(localized: "Cat Facts")
//         navigationController?.navigationBar.prefersLargeTitles = true
//         view.backgroundColor = .systemGroupedBackground
//         layoutViews()

//         refreshControl.addAction(UIAction { [weak self] _ in self?.load() }, for: .valueChanged)
//         // $state emits the current value on subscribe, so this also renders the initial state.
//         viewModel.$state
//             .sink { [weak self] state in self?.render(state) }
//             .store(in: &cancellables)
//         viewModel.$refreshError
//             .compactMap { $0 }
//             .sink { [weak self] error in self?.presentRefreshFailure(error) }
//             .store(in: &cancellables)

//         load()
//     }

//     private func load() {
//         loadTask = Task { [viewModel, refreshControl] in
//             await viewModel.load()
//             refreshControl.endRefreshing()
//         }
//     }

//     private func render(_ state: FactsViewModel.State) {
//         switch state {
//         case .loading:
//             statusController.view.isHidden = true
//             loadingIndicator.startAnimating()
//             show([])
//         case .loaded(let facts):
//             statusController.view.isHidden = true
//             loadingIndicator.stopAnimating()
//             show(facts)
//         case .empty:
//             loadingIndicator.stopAnimating()
//             show([])
//             showStatus(.empty)
//         case .failed(let error):
//             loadingIndicator.stopAnimating()
//             show([])
//             showStatus(.failure(error))
//         }
//     }

//     private func show(_ facts: [FactItem]) {
//         var snapshot = NSDiffableDataSourceSnapshot<Section, CatFact>()
//         snapshot.appendSections([.main])
//         snapshot.appendItems(facts)
//         dataSource.apply(snapshot, animatingDifferences: false)
//     }

//     private func showStatus(_ content: StatusView.Content) {
//         statusController.rootView = StatusView(content: content) { [weak self] in self?.load() }
//         statusController.view.isHidden = false
//         UIAccessibility.post(notification: .screenChanged, argument: statusController.view)
//     }

//     private func presentRefreshFailure(_ error: CatFactsError) {
//         guard presentedViewController == nil else { return }
//         let content = StatusView.Content.failure(error)
//         let alert = UIAlertController(title: content.title, message: content.message, preferredStyle: .alert)
//         alert.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
//         present(alert, animated: true)
//     }

//     private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, CatFact> {
//         let registration = UICollectionView.CellRegistration<UICollectionViewListCell, CatFact> { cell, _, fact in
//             var content = cell.defaultContentConfiguration()
//             content.text = fact.text
//             content.secondaryText = fact.createdAt.formatted(date: .abbreviated, time: .omitted)
//             content.secondaryTextProperties.color = .secondaryLabel
//             content.textToSecondaryTextVerticalPadding = 6
//             cell.contentConfiguration = content
//         }
//         return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, fact in
//             collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: fact)
//         }
//     }

//     private func layoutViews() {
//         addChild(statusController)
//         for subview: UIView in [collectionView, loadingIndicator, statusController.view] {
//             subview.translatesAutoresizingMaskIntoConstraints = false
//             view.addSubview(subview)
//         }
//         statusController.didMove(toParent: self)
//         statusController.view.backgroundColor = .clear

//         let safeArea = view.safeAreaLayoutGuide
//         NSLayoutConstraint.activate([
//             collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//             collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//             collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//             collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

//             loadingIndicator.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
//             loadingIndicator.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),

//             // Filling the safe area avoids sizing the hosted view by hand; sizingOptions needs iOS 16.
//             statusController.view.topAnchor.constraint(equalTo: safeArea.topAnchor),
//             statusController.view.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
//             statusController.view.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
//             statusController.view.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
//         ])
//     }
// }

extension StatusView.Content {
    static let empty = StatusView.Content(
        symbolName: "tray",
        title: String(localized: "No cat facts yet"),
        message: String(localized: "Check back later for new facts."),
        actionTitle: String(localized: "Refresh")
    )

    static func noResults(for query: String) -> StatusView.Content {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return StatusView.Content(
            symbolName: "magnifyingglass",
            title: String(localized: "No results"),
            message: String(localized: "No cat facts match “\(query)”."),
            actionTitle: nil
        )
    }

    static func failure(_ error: CatFactsError) -> StatusView.Content {
        let tryAgain = String(localized: "Try Again")
        switch error {
        case .connection:
            return StatusView.Content(
                symbolName: "wifi.slash",
                title: String(localized: "No connection"),
                message: String(localized: "Check your internet connection and try again."),
                actionTitle: tryAgain
            )
        case .server:
            return StatusView.Content(
                symbolName: "exclamationmark.icloud",
                title: String(localized: "Service unavailable"),
                message: String(localized: "Cat facts can't be loaded right now. Please try again later."),
                actionTitle: tryAgain
            )
        case .invalidData:
            return StatusView.Content(
                symbolName: "exclamationmark.triangle",
                title: String(localized: "Something went wrong"),
                message: String(localized: "We received cat facts we couldn't read. Please try again later."),
                actionTitle: tryAgain
            )
        case .unknown:
            return StatusView.Content(
                symbolName: "exclamationmark.triangle",
                title: String(localized: "Something went wrong"),
                message: String(localized: "Please try again."),
                actionTitle: tryAgain
            )
        }
    }
}
