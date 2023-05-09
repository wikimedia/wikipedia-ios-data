import Foundation

public struct WatchlistAPIResponse: Codable {
    
    public struct Query: Codable {
        
        public struct Item: Codable {
            public let title: String
            
            public init(title: String) {
                self.title = title
            }
        }
        
        public let watchlist: [Item]
        
        public init(watchlist: [Item]) {
            self.watchlist = watchlist
        }
    }
    
    public let query: Query
    
    public init(query: Query) {
        self.query = query
    }
}


public protocol WatchlistFetching {
    func fetchWatchlist(siteURL: URL, completion: @escaping (Result<WatchlistAPIResponse, Error>) -> Void)
}
