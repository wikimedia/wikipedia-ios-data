import Foundation

public protocol WKNetworkService {
	func perform(request: WKNetworkRequest, completion: Result<Any, Error>)
}
