import Foundation

struct CatFact: Hashable, Identifiable, Sendable {
    let id: String
    let text: String
    let isVerified: Bool
    let createdAt: Date
}
