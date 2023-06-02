import Foundation
import WKData

#if DEBUG

fileprivate enum WKMockError: Error {
    case unableToPullData
    case unableToDeserialize
}

fileprivate extension WKData.WKNetworkRequest {
    var isWatchlistGetList: Bool {
        guard let action = parameters?["action"] as? String,
              let list = parameters?["list"] as? String else {
            return false
        }
        
        return method == .GET && action == "query"
            && list == "watchlist"
    }
    
    var isWatchlistPostWatchArticleExpiryNever: Bool {
         guard let action = parameters?["action"] as? String,
               let expiry = parameters?["expiry"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && expiry == "never"
     }

     var isWatchlistPostWatchArticleExpiryDate: Bool {
         guard let action = parameters?["action"] as? String,
               let expiry = parameters?["expiry"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && (expiry == "1 week" ||
                                                         expiry == "1 month" ||
                                                         expiry == "3 months" ||
                                                         expiry == "6 months")
     }

     var isWatchlistPostUnwatchArticle: Bool {
         guard let action = parameters?["action"] as? String,
               let unwatch = parameters?["unwatch"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && unwatch == "1"
     }
}

public class WKMockWatchlistMediaWikiNetworkService: WKNetworkService {
    
    public init() {
        
    }
    
    public func perform(request: WKData.WKNetworkRequest, tokenType: WKData.WKNetworkRequest.TokenType?, completion: @escaping (Result<[String : Any]?, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            completion(.failure(WKMockError.unableToDeserialize))
            return
        }
        
        completion(.success(jsonDict))
    }
    
    public func performDecodableGET<T>(request: WKData.WKNetworkRequest, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WKMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WKMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    private func jsonData(for request: WKData.WKNetworkRequest) -> Data? {
        if request.isWatchlistGetList {
            guard let host = request.url?.host,
                  let index = host.firstIndex(of: "."),
                  let subdomain = request.url?.host?.prefix(upTo: index) else {
                return nil
            }
            
            let resourceName: String
            if subdomain == "commons" {
                resourceName = "watchlist-get-list-commons"
            } else if (request.url?.host ?? "").contains("wikidata") {
                resourceName = "watchlist-get-list-wikidata"
            } else {
                resourceName = "watchlist-get-list-\(subdomain)"
            }
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isWatchlistPostWatchArticleExpiryNever {
            guard let url = Bundle.module.url(forResource: "watchlist-post-watch-article-expiry-never", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostWatchArticleExpiryDate {
            guard let url = Bundle.module.url(forResource: "watchlist-post-watch-article-expiry-date", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostUnwatchArticle {
            guard let url = Bundle.module.url(forResource: "watchlist-post-unwatch-article", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        }
        
        return nil
    }
}

#endif
