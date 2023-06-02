import Foundation
import UIKit

public struct WKWatchlist {
    
    public struct Item {
        public let title: String
        public let revisionID: UInt
        public let oldRevisionID: UInt
        public let username: String
        public let isAnon: Bool
        public let isBot: Bool
        public let timestamp: Date
        public let commentHtml: String
        public let project: WKProject
    }
    
    public let items: [Item]
}

public enum WKWatchlistExpiryType: String {
    case never
    case oneWeek = "1 week"
    case oneMonth = "1 month"
    case threeMonths = "3 months"
    case sixMonths = "6 months"
}

public struct WKPageWatchStatus {
    public let watched: Bool
    public let userHasRollbackRights: Bool?
}

fileprivate struct WatchlistAPIResponse: Codable {
    
    struct Query: Codable {
        
        struct Item: Codable {
            let title: String
            let revisionID: UInt
            let oldRevisionID: UInt
            let username: String
            let isAnon: Bool
            let isBot: Bool
            let timestampString: String
            let commentHtml: String
            
            enum CodingKeys: String, CodingKey {
                case title
                case revisionID = "revid"
                case oldRevisionID = "old_revid"
                case username = "user"
                case isAnon = "anon"
                case isBot = "bot"
                case timestampString = "timestamp"
                case commentHtml = "parsedcomment"
            }
        }
        
        let watchlist: [Item]
    }
    
    let query: Query?
    let errors: [WKMediaWikiError]?
}

fileprivate struct PageWatchStatusAndRollbackResponse: Codable {

    struct Query: Codable {

        struct Page: Codable {
            let title: String
            let watched: Bool
        }

        struct UserInfo: Codable {
            let name: String
            let rights: [String]
        }

        let pages: [Page]
        let userinfo: UserInfo?
    }

    let query: Query
}

public class WKWatchlistService {

    public enum WKWatchlistServiceError: Error {
        case unexpectedResponse
        case networkFailure(Error)
        case mediawikiServiceUnavailable
        case unabletoDetermineProject
        case appLanguagesUnavailable
    }

    public init() { }
    
    // MARK: GET Watchlist Items

    public func fetchWatchlist(completion: @escaping (Result<WKWatchlist, Error>) -> Void) {
        
        guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
            completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
            return
        }
        
        let appLanguages = WKDataEnvironment.current.appData.appLanguages
        guard !appLanguages.isEmpty else {
            completion(.failure(WKWatchlistServiceError.appLanguagesUnavailable))
            return
        }
        
        var parameters = [
                    "action": "query",
                    "list": "watchlist",
                    "wllimit": "500",
                    "wlallrev": "1",
                    "wlprop": "ids|title|flags|comment|parsedcomment|timestamp|sizes|user|loginfo",
                    "errorsuselocal": "1",
                    "errorformat": "html",
                    "format": "json",
                    "formatversion": "2"
                ]

        var projects = WKProject.projectsFromLanguages(languages:appLanguages)
        projects.append(.commons)
        projects.append(.wikidata)
        
        let group = DispatchGroup()
        var items: [WKWatchlist.Item] = []
        var errors: [Error] = []
        
        for project in projects {
            
            guard let url = URL.mediaWikiAPIURL(project: project) else {
                return
            }
            
            parameters["variant"] = project.languageVariantCode
            
            group.enter()
            let request = WKNetworkRequest(url: url, method: .GET, parameters: parameters)
            networkService.performDecodableGET(request: request) { [weak self] (result: Result<WatchlistAPIResponse, Error>) in
                
                guard let self else {
                    return
                }
                
                defer {
                    group.leave()
                }
                
                switch result {
                case .success(let apiResponse):
                    
                    if let apiResponseErrors = apiResponse.errors,
                       !apiResponseErrors.isEmpty {
                        errors.append(contentsOf: apiResponseErrors)
                        return
                    }
                    
                    guard let query = apiResponse.query else {
                        errors.append(WKWatchlistServiceError.unexpectedResponse)
                        return
                    }
                    
                    items.append(contentsOf: self.watchlistItems(from: query, project: project))
                    
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        
        group.notify(queue: .main) {
        
            if let error = errors.first {
                completion(.failure(error))
                return
            }
            
            completion(.success(WKWatchlist(items: items)))
        }
    }
    
    private func watchlistItems(from apiResponseQuery: WatchlistAPIResponse.Query, project: WKProject) -> [WKWatchlist.Item] {
        
        var items: [WKWatchlist.Item] = []
        for item in apiResponseQuery.watchlist {
            
            guard let timestamp = DateFormatter.mediaWikiAPIDateFormatter.date(from: item.timestampString) else {
                continue
            }
            
            let item = WKWatchlist.Item(title: item.title, revisionID: item.revisionID, oldRevisionID: item.oldRevisionID, username: item.username, isAnon: item.isAnon, isBot: item.isBot, timestamp: timestamp, commentHtml: item.commentHtml, project: project)
            items.append(item)
        }
        
        return items
    }
    
    // MARK: POST Watch Item
     
     public func watch(title: String, project: WKProject, expiry: WKWatchlistExpiryType, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
             completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
             return
         }

         let parameters = [
             "action": "watch",
             "titles": title,
             "expiry": expiry.rawValue,
             "format": "json",
             "formatversion": "2",
             "errorformat": "html",
             "errorsuselocal": "1"
         ]

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             completion(.failure(WKWatchlistServiceError.unabletoDetermineProject))
             return
         }

         let request = WKNetworkRequest(url: url, method: .POST, parameters: parameters)
         networkService.perform(request: request, tokenType: .watch) { result in
             switch result {
             case .success(let response):
                 guard let watched = (response?["watch"] as? [[String: Any]])?.first?["watched"] as? Bool,
                 watched == true else {
                     completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 print(error)
             }
         }
     }

     // MARK: POST Unwatch Item
     
     public func unwatch(title: String, project: WKProject, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
             completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
             return
         }

         let parameters = [
             "action": "watch",
             "unwatch": "1",
             "titles": title,
             "format": "json",
             "formatversion": "2",
             "errorformat": "html",
             "errorsuselocal": "1"
         ]

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             completion(.failure(WKWatchlistServiceError.unabletoDetermineProject))
             return
         }

         let request = WKNetworkRequest(url: url, method: .POST, parameters: parameters)
         networkService.perform(request: request, tokenType: .watch) { result in
             switch result {
             case .success(let response):
                 guard let unwatched = (response?["watch"] as? [[String: Any]])?.first?["unwatched"] as? Bool,
                       unwatched == true else {
                     completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 print(error)
             }
         }
     }
    
    // MARK: GET Watch Status and Rollback Rights
     
     public func fetchWatchStatus(title: String, project: WKProject, needsRollbackRights: Bool = false, completion: @escaping (Result<WKPageWatchStatus, Error>) -> Void) {
         guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
             completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
             return
         }

         var parameters = [
                     "action": "query",
                     "prop": "info",
                     "inprop": "watched",
                     "titles": title,
                     "errorsuselocal": "1",
                     "errorformat": "html",
                     "format": "json",
                     "formatversion": "2"
                 ]

         if needsRollbackRights {
             parameters["meta"] = "userinfo"
             parameters["uiprop"] = "rights"
         }

         guard let url = URL.mediaWikiAPIURL(project: project) else {
             return
         }

         let request = WKNetworkRequest(url: url, method: .GET, parameters: parameters)

         networkService.performDecodableGET(request: request) { (result: Result<PageWatchStatusAndRollbackResponse, Error>) in
             switch result {
             case .success(let response):

                 guard let watched = response.query.pages.first?.watched else {
                     completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                     return
                 }

                 let userHasRollbackRights = response.query.userinfo?.rights.contains("rollback")
                 let status = WKPageWatchStatus(watched: watched, userHasRollbackRights: userHasRollbackRights)
                 completion(.success(status))
             case .failure(let error):
                 completion(.failure(error))
             }
         }
     }
}
