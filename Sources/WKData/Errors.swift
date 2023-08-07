import Foundation

public enum WKDataControllerError: Error {
    case mediawikiServiceUnavailable
    case unabletoDetermineProject
    case appLanguagesUnavailable
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
}
