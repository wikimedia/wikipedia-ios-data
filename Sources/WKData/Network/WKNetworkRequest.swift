import Foundation

public struct WKNetworkRequest {

	public enum Method: String {
		case GET
		case POST
		case PUT
		case DELETE
		case HEAD
	}

	public let url: URL?
	public let method: Method
	public let parameters: [String: Any]?

}
