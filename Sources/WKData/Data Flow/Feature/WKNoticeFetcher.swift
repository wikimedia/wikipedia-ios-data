import Foundation

public class WKNoticeFetcher {

	let networkService: WKNetworkService

	public init(networkService: WKNetworkService) {
		self.networkService = networkService
	}

	public func fetchNotices(for title: String, completion: @escaping (Result<[WKNotice], Error>) -> Void) {
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
			dump(result)
		})
	}

}
