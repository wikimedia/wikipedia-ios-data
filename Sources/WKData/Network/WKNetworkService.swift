import Foundation

public protocol WKNetworkService {
    func perform(request: WKNetworkRequest, tokenType: WKNetworkRequest.TokenType?, completion: @escaping (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<T: Decodable>(request: WKNetworkRequest, completion: @escaping (Result<T, Error>) -> Void)
}
