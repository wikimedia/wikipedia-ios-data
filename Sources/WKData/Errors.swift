import Foundation

public enum WKDataControllerError: Error {
    case mediaWikiServiceUnavailable
    case appLanguagesUnavailable
    case failureCreatingRequestURL
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
}
