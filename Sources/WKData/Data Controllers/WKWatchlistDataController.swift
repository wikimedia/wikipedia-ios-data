import Foundation
import UIKit

public class WKWatchlistDataController {

    public init() { }
    
    // MARK: GET Watchlist Items

    public func fetchWatchlist(completion: @escaping (Result<WKWatchlist, Error>) -> Void) {
        
        guard let service = WKDataEnvironment.current.mediaWikiService else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
            return
        }
        
        let appLanguages = WKDataEnvironment.current.appData.appLanguages
        guard !appLanguages.isEmpty else {
            completion(.failure(WKDataControllerError.appLanguagesUnavailable))
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
        var errors: [WKProject: [WKDataControllerError]] = [:]
        projects.forEach { project in
            errors[project] = []
        }
        
        for project in projects {
            
            guard let url = URL.mediaWikiAPIURL(project: project) else {
                return
            }
            
            parameters["variant"] = project.languageVariantCode
            
            group.enter()
            let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)
            service.performDecodableGET(request: request) { [weak self] (result: Result<WatchlistAPIResponse, Error>) in
                
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
                        
                        let mediaWikiResponseErrors = apiResponseErrors.map { WKDataControllerError.mediaWikiResponseError($0) }
                        errors[project, default: []].append(contentsOf: mediaWikiResponseErrors)
                        return
                    }
                    
                    guard let query = apiResponse.query else {
                        errors[project, default: []].append(WKDataControllerError.unexpectedResponse)
                        return
                    }
                    
                    items.append(contentsOf: self.watchlistItems(from: query, project: project))
                    
                case .failure(let error):
                    errors[project, default: []].append(WKDataControllerError.serviceError(error))
                }
            }
        }
        
        group.notify(queue: .main) {
        
            let successProjects = errors.filter { $0.value.isEmpty }
            let failureProjects = errors.filter { !$0.value.isEmpty }
            
            if !successProjects.isEmpty {
                completion(.success(WKWatchlist(items: items)))
                return
            }
            
            if let error = failureProjects.first?.value.first {
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
                commentWikitext: item.commentWikitext,
                commentHtml: item.commentHtml,
                byteLength: item.byteLength,
                oldByteLength: item.oldByteLength,
                project: project)
            items.append(item)
        }
        
        return items
    }
    
    // MARK: POST Watch Item
     
     public func watch(title: String, project: WKProject, expiry: WKWatchlistExpiryType, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let service = WKDataEnvironment.current.mediaWikiService else {
             completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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
             completion(.failure(WKDataControllerError.failureCreatingRequestURL))
             return
         }

         let request = WKMediaWikiServiceRequest(url: url, method: .POST, tokenType: .watch, parameters: parameters)
         service.perform(request: request) { result in
             switch result {
             case .success(let response):
                 guard let watched = (response?["watch"] as? [[String: Any]])?.first?["watched"] as? Bool,
                 watched == true else {
                     completion(.failure(WKDataControllerError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 completion(.failure(WKDataControllerError.serviceError(error)))
             }
         }
     }

     // MARK: POST Unwatch Item
     
     public func unwatch(title: String, project: WKProject, completion: @escaping (Result<Void, Error>) -> Void) {

         guard let service = WKDataEnvironment.current.mediaWikiService else {
             completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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
             completion(.failure(WKDataControllerError.failureCreatingRequestURL))
             return
         }

         let request = WKMediaWikiServiceRequest(url: url, method: .POST, tokenType: .watch, parameters: parameters)
         service.perform(request: request) { result in
             switch result {
             case .success(let response):
                 guard let unwatched = (response?["watch"] as? [[String: Any]])?.first?["unwatched"] as? Bool,
                       unwatched == true else {
                     completion(.failure(WKDataControllerError.unexpectedResponse))
                     return
                 }

                 completion(.success(()))
             case .failure(let error):
                 completion(.failure(WKDataControllerError.serviceError(error)))
             }
         }
     }
    
    // MARK: GET Watch Status and Rollback Rights
     
     public func fetchWatchStatus(title: String, project: WKProject, needsRollbackRights: Bool = false, completion: @escaping (Result<WKPageWatchStatus, Error>) -> Void) {
         guard let service = WKDataEnvironment.current.mediaWikiService else {
             completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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

         let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)

         service.performDecodableGET(request: request) { (result: Result<PageWatchStatusAndRollbackResponse, Error>) in
             switch result {
             case .success(let response):

                 guard let watched = response.query.pages.first?.watched else {
                     completion(.failure(WKDataControllerError.unexpectedResponse))
                     return
                 }

                 let userHasRollbackRights = response.query.userinfo?.rights.contains("rollback")
                 let status = WKPageWatchStatus(watched: watched, userHasRollbackRights: userHasRollbackRights)
                 completion(.success(status))
             case .failure(let error):
                 completion(.failure(WKDataControllerError.serviceError(error)))
             }
         }
     }
    
    // MARK: POST Rollback Page
    
    public func rollback(title: String, project: WKProject, username: String, completion: @escaping (Result<WKUndoOrRollbackResult, Error>) -> Void) {
        
        guard let service = WKDataEnvironment.current.mediaWikiService else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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
            completion(.failure(WKDataControllerError.failureCreatingRequestURL))
            return
        }

        let request = WKMediaWikiServiceRequest(url: url, method: .POST, tokenType: .rollback, parameters: parameters)
        service.perform(request: request) { result in
            switch result {
            case .success(let response):
                guard let rollback = (response?["rollback"] as? [String: Any]),
                    let newRevisionID = rollback["revid"] as? Int,
                    let oldRevisionID = rollback["old_revid"] as? Int else {
                    completion(.failure(WKDataControllerError.unexpectedResponse))
                    return
                }

                completion(.success(WKUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
            case .failure(let error):
                completion(.failure(WKDataControllerError.serviceError(error)))
            }
        }
    }
    
    // MARK: POST Undo Revision
    
    public func undo(title: String, revisionID: UInt, summary: String, username: String, project: WKProject, completion: @escaping (Result<WKUndoOrRollbackResult, Error>) -> Void) {

        guard let service = WKDataEnvironment.current.mediaWikiService else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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
                    completion(.failure(WKDataControllerError.failureCreatingRequestURL))
                    return
                }

                let request = WKMediaWikiServiceRequest(url: url, method: .POST, tokenType: .csrf, parameters: parameters)
                service.perform(request: request) { result in
                    switch result {
                    case .success(let response):
                        guard let edit = (response?["edit"] as? [String: Any]),
                              let result = edit["result"] as? String,
                              result == "Success",
                              let newRevisionID = edit["newrevid"] as? Int,
                              let oldRevisionID = edit["oldrevid"] as? Int else {
                            completion(.failure(WKDataControllerError.unexpectedResponse))
                            return
                        }

                        completion(.success(WKUndoOrRollbackResult(newRevisionID: newRevisionID, oldRevisionID: oldRevisionID)))
                    case .failure(let error):
                        completion(.failure(WKDataControllerError.serviceError(error)))
                    }
                }
                
            case .failure(let error):
                completion(.failure(WKDataControllerError.serviceError(error)))
            }
        }
    }
    
    private func fetchUndoRevisionSummaryPrefixText(revisionID: UInt, username: String, project: WKProject, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let service = WKDataEnvironment.current.mediaWikiService else {
            completion(.failure(WKDataControllerError.mediaWikiServiceUnavailable))
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

        let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)

        service.performDecodableGET(request: request) { (result: Result<UndoRevisionSummaryTextResponse, Error>) in
            switch result {
            case .success(let response):
                
                guard let undoSummaryMessage = response.query.messages.first(where: { message in
                    message.name == "undo-summary"
                }) else {
                    completion(.failure(WKDataControllerError.unexpectedResponse))
                    return
                }
                
                completion(.success(undoSummaryMessage.content))
            case .failure(let error):
                completion(.failure(WKDataControllerError.serviceError(error)))
            }
        }
    }
}

// MARK: - Private Models

private extension WKWatchlistDataController {
    struct WatchlistAPIResponse: Codable {
        
        struct Query: Codable {
            
            struct Item: Codable {
                let title: String
                let revisionID: UInt
                let oldRevisionID: UInt
                let username: String
                let isAnon: Bool
                let isBot: Bool
                let timestampString: String
                let commentWikitext: String
                let commentHtml: String
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

    struct PageWatchStatusAndRollbackResponse: Codable {

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

    struct UndoRevisionSummaryTextResponse: Codable {
        
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
}
