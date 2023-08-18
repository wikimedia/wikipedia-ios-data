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
        public let commentWikitext: String
        public let commentHtml: String
        public let byteLength: UInt
        public let oldByteLength: UInt
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
    case oneYear = "1 year"
}

public struct WKPageWatchStatus {
    public let watched: Bool
    public let userHasRollbackRights: Bool?
}

public struct WKUndoOrRollbackResult: Codable {
    public let newRevisionID: Int
    public let oldRevisionID: Int
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
            let commentWikitext: String?
            let commentHtml: String?
            let byteLength: UInt
            let oldByteLength: UInt
            
            enum CodingKeys: String, CodingKey {
                case title
                case revisionID = "revid"
                case oldRevisionID = "old_revid"
                case username = "user"
                case isAnon = "anon"
                case isBot = "bot"
                case timestampString = "timestamp"
                case commentWikitext = "comment"
                case commentHtml = "parsedcomment"
                case byteLength = "newlen"
                case oldByteLength = "oldlen"
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

fileprivate struct UndoRevisionSummaryTextResponse: Codable {
    
    struct Query: Codable {
        
        struct Messages: Codable {
            let name: String
            let content: String
        }
        
        let messages: [Messages]
        
        enum CodingKeys: String, CodingKey {
            case messages = "allmessages"
        }
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
            
            let item = WKWatchlist.Item(
                title: item.title,
                revisionID: item.revisionID,
                oldRevisionID: item.oldRevisionID,
                username: item.username,
                isAnon: item.isAnon,
                isBot: item.isBot,
                timestamp: timestamp,
                commentWikitext: item.commentWikitext ?? "",
                commentHtml: item.commentHtml ?? "",
                byteLength: item.byteLength,
                oldByteLength: item.oldByteLength,
                project: project)
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
                 completion(.failure(error))
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
                 completion(.failure(error))
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
    
    // MARK: POST Rollback Page
    
    public func rollback(title: String, project: WKProject, username: String, completion: @escaping (Result<WKUndoOrRollbackResult, Error>) -> Void) {
        
        guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
            completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
            return
        }

        let parameters = [
            "action": "rollback",
            "title": title,
            "user": username,
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
        networkService.perform(request: request, tokenType: .rollback) { result in
            switch result {
            case .success(let response):
                guard let rollback = (response?["rollback"] as? [String: Any]),
                    let newRevisionID = rollback["revid"] as? Int,
                    let oldRevisionID = rollback["old_revid"] as? Int else {
                    completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                    return
                }

                completion(.success(WKUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: POST Undo Revision
    
    public func undo(title: String, revisionID: UInt, summary: String, username: String, project: WKProject, completion: @escaping (Result<WKUndoOrRollbackResult, Error>) -> Void) {

        guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
            completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
            return
        }
        
        fetchUndoRevisionSummaryPrefixText(revisionID: revisionID, username: username, project: project) { result in
            switch result {
            case .success(let summaryPrefix):
                
                let parameters = [
                    "action": "edit",
                    "title": title,
                    "summary": summaryPrefix + " " + summary,
                    "undo": String(revisionID),
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
                networkService.perform(request: request, tokenType: .csrf) { result in
                    switch result {
                    case .success(let response):
                        guard let edit = (response?["edit"] as? [String: Any]),
                              let result = edit["result"] as? String,
                              result == "Success",
                              let newRevisionID = edit["newrevid"] as? Int,
                              let oldRevisionID = edit["oldrevid"] as? Int else {
                            completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                            return
                        }

                        completion(.success(WKUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchUndoRevisionSummaryPrefixText(revisionID: UInt, username: String, project: WKProject, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let networkService = WKDataEnvironment.current.mediaWikiNetworkService else {
            completion(.failure(WKWatchlistServiceError.mediawikiServiceUnavailable))
            return
        }

        let parameters = [
                    "action": "query",
                    "meta": "allmessages",
                    "amenableparser": "1",
                    "ammessages": "undo-summary",
                    "amargs": "\(revisionID)|\(username)",
                    "errorsuselocal": "1",
                    "errorformat": "html",
                    "format": "json",
                    "formatversion": "2"
                ]

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            return
        }

        let request = WKNetworkRequest(url: url, method: .GET, parameters: parameters)

        networkService.performDecodableGET(request: request) { (result: Result<UndoRevisionSummaryTextResponse, Error>) in
            switch result {
            case .success(let response):
                
                guard let undoSummaryMessage = response.query.messages.first(where: { message in
                    message.name == "undo-summary"
                }) else {
                    completion(.failure(WKWatchlistServiceError.unexpectedResponse))
                    return
                }
                
                completion(.success(undoSummaryMessage.content))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
