import Foundation

struct WatchlistAPIResponse: Codable {
    
    struct Query: Codable {
        
        struct Item: Codable {
            let title: String
        }
        
        let watchlist: [Item]
    }
    
    let query: Query
}


public protocol WatchlistFetching {
    var languageCodes: [String] { get }
    func fetchWatchlist(completion: (Result<WatchlistAPIResponse, Error>) -> Void)
}
