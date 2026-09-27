import Foundation

/// App-wide configuration values.
enum AppConstants {
    /// The endpoint that returns the list of cat facts.
    static let catFactsURL = URL(string: "https://api.npoint.io/18962a8a5d00e62a8d2a")!

    /// A fact is new when it was created within this many days.
    static let newFactThresholdInDays = 90
}
