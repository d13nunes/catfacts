import SwiftUI

// SwiftUI's navigationTitle and searchable only reach a SwiftUI navigation container. These modifiers configure the
// navigation item of the `HostingViewController` hosting the view instead, for views in a UIKit navigation stack.
// Outside a `HostingViewController` they do nothing.

extension View {
    /// Sets the navigation bar title, and updates it when `title` changes.
    func navigationItemTitle(_ title: String) -> some View {
        modifier(NavigationItemTitle(title: title))
    }

    /// Shows a search field in the navigation bar and writes what the user types into `text`.
    func navigationSearchBar(text: Binding<String>, placeholder: String) -> some View {
        modifier(NavigationSearchBar(text: text, placeholder: placeholder))
    }
}

private struct NavigationItemTitle: ViewModifier {
    @Environment(\.hostingNavigationItem) private var navigationItem
    let title: String

    func body(content: Content) -> some View {
        content
            .onAppear { navigationItem?.title = title }
            .onChange(of: title) { navigationItem?.title = $0 }
    }
}

private struct NavigationSearchBar: ViewModifier {
    @Environment(\.hostingNavigationItem) private var navigationItem
    let text: Binding<String>
    let placeholder: String

    func body(content: Content) -> some View {
        content.onAppear {
            // Install once: the view appears again when a screen pushed on top of it is popped.
            guard let navigationItem, navigationItem.searchController == nil else { return }
            navigationItem.searchController = SearchController(placeholder: placeholder) { text.wrappedValue = $0 }
        }
    }
}
