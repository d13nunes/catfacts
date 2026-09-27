extension StatusView.Content {
    static let empty = StatusView.Content(
        symbolName: "tray",
        title: "No cat facts yet",
        message: "Check back later for new facts.",
        actionTitle: "Refresh"
    )

    static func noResults(for query: String) -> StatusView.Content {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return StatusView.Content(
            symbolName: "magnifyingglass",
            title: "No results",
            message: "No cat facts match “\(query)”.",
            actionTitle: nil
        )
    }

    static func failure(_ error: CatFactsError) -> StatusView.Content {
        let tryAgain = "Try Again"
        switch error {
        case .connection:
            return StatusView.Content(
                symbolName: "wifi.slash",
                title: "No connection",
                message: "Check your internet connection and try again.",
                actionTitle: tryAgain
            )
        case .server:
            return StatusView.Content(
                symbolName: "exclamationmark.icloud",
                title: "Service unavailable",
                message: "Cat facts can't be loaded right now. Please try again later.",
                actionTitle: tryAgain
            )
        case .invalidData:
            return StatusView.Content(
                symbolName: "exclamationmark.triangle",
                title: "Something went wrong",
                message: "We received cat facts we couldn't read. Please try again later.",
                actionTitle: tryAgain
            )
        case .unknown:
            return StatusView.Content(
                symbolName: "exclamationmark.triangle",
                title: "Something went wrong",
                message: "Please try again.",
                actionTitle: tryAgain
            )
        }
    }
}
