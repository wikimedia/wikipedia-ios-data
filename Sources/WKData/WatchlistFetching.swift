import Foundation

public struct WatchlistAPIResponse: Codable {
    
    struct Query: Codable {
        
        struct Item: Codable {
            let title: String
        }
        
        let watchlist: [Item]
    }
    
    let query: Query
}


public protocol WatchlistFetching {
    func fetchWatchlist(siteURL: URL, completion: @escaping (Result<WatchlistAPIResponse, Error>) -> Void)
}
