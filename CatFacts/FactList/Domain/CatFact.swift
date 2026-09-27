import Foundation

struct CatFact: Equatable, Sendable {
    let id: String
    let text: String
    let isVerified: Bool
    let createdAt: Date
}
