import Foundation

public struct WatchlistItem {
    public let title: String
}

public final class WatchlistService {
    private let siteURLs: [URL]
    private let fetcher: WatchlistFetching
    
    public init(siteURLs: [URL], fetcher: WatchlistFetching) {
        self.siteURLs = siteURLs
        self.fetcher = fetcher
    }
    
    public func fetchWatchlist(completion: @escaping (Result<[WatchlistItem], Error>) -> Void) {
        
        let group = DispatchGroup()
        
        var items: [WatchlistItem] = []
        var errors: [Error] = []
        
        for siteURL in siteURLs {
            
            group.enter()
            fetcher.fetchWatchlist(siteURL: siteURL) { result in
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let response):
                    
                    items.append(contentsOf: response.query.watchlist.map { WatchlistItem(title: $0.title) })
                    
                    // TODO: We could save to persistence here before returning

                case .failure(let error):
                    errors.append(error)
                    
                    // TODO: We could check for network connection error, and attempt to return from persistence
                }
            }
        }
        
        group.notify(queue: .main) {
            if let firstError = errors.first {
                completion(.failure(firstError))
                return
            }
            
            completion(.success(items))
        }
    }
}
