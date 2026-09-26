import UIKit

/// A navigation-bar search field that reports its text through a closure, so the owner doesn't have to be the
/// `UISearchResultsUpdating` object. SwiftUI's `.searchable` only works inside a SwiftUI navigation container.
final class SearchController: UISearchController, UISearchResultsUpdating {
    private var onTextChange: (String) -> Void = { _ in }

    // A convenience init keeps UISearchController's designated initializers, which it calls internally.
    convenience init(placeholder: String, onTextChange: @escaping (String) -> Void) {
        self.init(searchResultsController: nil)
        self.onTextChange = onTextChange
        searchResultsUpdater = self
        obscuresBackgroundDuringPresentation = false
        searchBar.placeholder = placeholder
    }

    func updateSearchResults(for searchController: UISearchController) {
        onTextChange(searchController.searchBar.text ?? "")
    }
}
