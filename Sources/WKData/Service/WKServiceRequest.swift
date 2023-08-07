import Foundation

public struct WKServiceRequest {
    public enum TokenType {
        case csrf
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

    internal init(url: URL? = nil, method: WKServiceRequest.Method, tokenType: WKServiceRequest.TokenType? = nil, parameters: [String : Any]? = nil) {
        self.url = url
        self.method = method
        self.tokenType = tokenType
        self.parameters = parameters
    }
}
