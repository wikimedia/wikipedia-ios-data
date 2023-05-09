import XCTest
@testable import WKData

public class MockWatchlistFetcher: WatchlistFetching {
    public let languageCodes: [String]
    public init(languageCodes: [String]) {
        self.languageCodes = languageCodes
    }
    
    public func fetchWatchlist(completion: (Result<WKData.WatchlistAPIResponse, Error>) -> Void) {
        let item1 = WatchlistAPIResponse.Query.Item(title: "Item 1")
        let item2 = WatchlistAPIResponse.Query.Item(title: "Item 2")
        let item3 = WatchlistAPIResponse.Query.Item(title: "Item 3")
        let response = WatchlistAPIResponse(query: WatchlistAPIResponse.Query(watchlist: [item1, item2, item3]))
        completion(.success(response))
    }
    
    
}

final class WKDataTests: XCTestCase {
    func testWatchlistService() throws {
        let fetcher = MockWatchlistFetcher(languageCodes: ["en"])
        let service = WatchlistService(fetcher: fetcher)
        service.fetchWatchlist { response in
            switch response {
            case .success(let items):
                XCTAssertEqual(items.count, 3)
                let item1 = items[0]
                XCTAssertEqual(item1.title, "Item 1")
                let item2 = items[1]
                XCTAssertEqual(item2.title, "Item 2")
                let item3 = items[2]
                XCTAssertEqual(item3.title, "Item 3")
            case .failure(let error):
                XCTFail("Unexpected WatchlistService failure: \(error)")
            }
            
        }
    }
}
