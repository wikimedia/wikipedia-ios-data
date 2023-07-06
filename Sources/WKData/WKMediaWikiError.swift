import Foundation

struct WKMediaWikiError: Codable, Error {
    let code: String
    let html: String
}
