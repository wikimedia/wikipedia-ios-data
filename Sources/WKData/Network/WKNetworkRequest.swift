import Foundation

public struct WKNetworkRequest {
    public enum TokenType {
        case watch
        case rollback
    }

	public enum Method: String {
		case GET
		case POST
		case PUT
		case DELETE
		case HEAD
	}

	public let url: URL?
	public let method: Method
    public let tokenType: TokenType?
	public let parameters: [String: Any]?

    internal init(url: URL? = nil, method: WKNetworkRequest.Method, tokenType: WKNetworkRequest.TokenType? = nil, parameters: [String : Any]? = nil) {
        self.url = url
        self.method = method
        self.tokenType = tokenType
        self.parameters = parameters
    }
}
