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
