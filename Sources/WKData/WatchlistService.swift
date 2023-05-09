import Foundation

public struct WatchlistItem {
    let title: String
}

public final class WatchlistService {
    private let fetcher: WatchlistFetching
    
    public init(fetcher: WatchlistFetching) {
        self.fetcher = fetcher
    }
    
    public func fetchWatchlist(completion: (Result<[WatchlistItem], Error>) -> Void) {
        fetcher.fetchWatchlist { result in
            switch result {
            case .success(let response):
                
                let items = response.query.watchlist.map { WatchlistItem(title: $0.title) }
                
                // TODO: We could save to persistence here before returning
                
                completion(.success(items))
            case .failure(let error):
                completion(.failure(error))
                
                // TODO: We could check for network connection error, and attempt to return from persistence
            }
        }
    }
}
