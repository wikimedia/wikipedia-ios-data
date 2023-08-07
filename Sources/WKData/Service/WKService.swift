import Foundation

public protocol WKService {
    func perform(request: WKServiceRequest, tokenType: WKServiceRequest.TokenType?, completion: @escaping (Result<[String: Any]?, Error>) -> Void)
    func performDecodableGET<T: Decodable>(request: WKServiceRequest, completion: @escaping (Result<T, Error>) -> Void)
}
