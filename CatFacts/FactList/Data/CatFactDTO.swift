import Foundation

struct CatFactDTO: Decodable, Sendable {
    struct Status: Decodable, Sendable {
        let verified: Bool
    }

    let id: String
    let text: String
    let status: Status
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text, status, createdAt
    }

    static let decoder: JSONDecoder = {
        // POSIX locale keeps parsing independent of the device's calendar and 12/24-hour settings.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss Z"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()

    var domain: CatFact {
        CatFact(id: id, text: text, isVerified: status.verified, createdAt: createdAt)
    }
}
