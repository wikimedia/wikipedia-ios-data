import Foundation

public enum WKCommonError: Error {
    case mediawikiServiceUnavailable
    case unabletoDetermineProject
    case appLanguagesUnavailable
    case unexpectedResponse
    case serviceError(Error)
    case mediaWikiResponseError(WKMediaWikiError)
}
