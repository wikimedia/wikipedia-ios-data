import XCTest
@testable import WKData

private class MockWatchlistFetcher: WatchlistFetching {

    func fetchWatchlist(siteURL: URL, completion: (Result<WKData.WatchlistAPIResponse, Error>) -> Void) {
        let item1 = WatchlistAPIResponse.Query.Item(title: "\(siteURL.host ?? "") Item 1")
        let item2 = WatchlistAPIResponse.Query.Item(title: "\(siteURL.host ?? "") Item 1")
        let item3 = WatchlistAPIResponse.Query.Item(title: "\(siteURL.host ?? "") Item 1")
        let response = WatchlistAPIResponse(query: WatchlistAPIResponse.Query(watchlist: [item1, item2, item3]))
        completion(.success(response))
    }
    
    
}

final class WKDataTests: XCTestCase {
    func testWatchlistService() throws {
        let fetcher = MockWatchlistFetcher()
        let service = WatchlistService(siteURLs: [URL(string: "https://en.wikipedia.org")!,
                                                  URL(string: "https://es.wikipedia.org")!], fetcher: fetcher)
        service.fetchWatchlist { response in
            switch response {
            case .success(let items):
                XCTAssertEqual(items.count, 6)
                let item1 = items[0]
                XCTAssertEqual(item1.title, "en.wikipedia.org Item 1")
                let item2 = items[1]
                XCTAssertEqual(item2.title, "en.wikipedia.org Item 2")
                let item3 = items[2]
                XCTAssertEqual(item3.title, "en.wikipedia.org Item 3")
                let item4 = items[3]
                XCTAssertEqual(item4.title, "en.wikipedia.org Item 4")
                let item5 = items[4]
                XCTAssertEqual(item5.title, "en.wikipedia.org Item 5")
                let item6 = items[5]
                XCTAssertEqual(item6.title, "en.wikipedia.org Item 6")
            case .failure(let error):
                XCTFail("Unexpected WatchlistService failure: \(error)")
            }
            
        }
    }
}
