import Foundation

public struct WKNetworkRequest {

	public enum Method: String {
		case GET
	}

	public let url: URL?
	public let method: Method
	public let parameters: [String: Any]?

}
