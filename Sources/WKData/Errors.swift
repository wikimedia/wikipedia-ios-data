import Foundation

// MARK: Common

public enum WKDataControllerError: Error {
    case mediaWikiServiceUnavailable
    case failureCreatingRequestURL
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
}

public enum WKUserDefaultsStoreError: Error {
    case unexpectedType
    case failureDecodingJSON(Error)
    case failureEncodingJSON(Error)
}

// MARK: Feature-specific

public enum WKWatchlistError: Error {
    case failureDeterminingProjects
}
