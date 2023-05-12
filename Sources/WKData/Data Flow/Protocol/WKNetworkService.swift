import Foundation

public protocol WKNetworkService {
	func perform(request: WKNetworkRequest, completion: @escaping (Result<String, Error>) -> Void)
}
