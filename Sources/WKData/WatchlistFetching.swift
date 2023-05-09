import Foundation

public struct WatchlistAPIResponse: Codable {
    
    public struct Query: Codable {
        
        public struct Item: Codable {
            public init(title: String) {
                self.title = title
            }
            
            public let title: String
        }
        
        public let watchlist: [Item]
    }
    
    public let query: Query
}


public protocol WatchlistFetching {
    func fetchWatchlist(siteURL: URL, completion: @escaping (Result<WatchlistAPIResponse, Error>) -> Void)
}
