import Foundation

public class WKNoticeFetcher {

	public enum WKNoticeFetcherError: Error {
		case someFetcherError
		case mediawikiServiceUnavailable
	}

	public func fetchNotices(for title: String, completion: @escaping (Result<[WKNotice], WKNoticeFetcherError>) -> Void) {
		guard let networkService = WKDataEnvironment.current.mediawikiNetworkService else {
			completion(.failure(WKNoticeFetcherError.mediawikiServiceUnavailable))
			return
		}

		let parameters: [String: Any] = [
			"action": "visualeditor",
			"paction": "metadata",
			"page": title,
			"errorsuselocal": "1",
			"formatversion" : "2",
			"format": "json"
		]

		let url = URL(string: "https://en.wikipedia.org/wiki/\(title)")
		let request = WKNetworkRequest(url: url, method: .GET, parameters: parameters)

		networkService.perform(request: request, completion: { result in
			if case let .success(dictionary) = result {
				// decode
				completion(
					.success(
						[WKNotice(name: dictionary?.description ?? "", description: "")]
					)
				)
			} else if case let .failure(error) = result {
				// parse error
				dump(error)
				completion(.failure(WKNoticeFetcherError.someFetcherError))
			}
		})
	}

}
