import XCTest
@testable import WKData
@testable import WKDataMocks

final class WKWatchlistFetcherTests: XCTestCase {
    
    private let enProject = WKProject.wikipedia(WKLanguage(languageCode: "en", languageVariantCode: nil))
    private let esProject = WKProject.wikipedia(WKLanguage(languageCode: "es", languageVariantCode: nil))
    
    override func setUp() async throws {
        WKDataEnvironment.current.appData = WKAppData(appLanguages:[
            WKLanguage(languageCode: "en", languageVariantCode: nil),
            WKLanguage(languageCode: "es", languageVariantCode: nil)
        ])
        WKDataEnvironment.current.mediaWikiNetworkService = WKMockWatchlistMediaWikiNetworkService()
    }
    
    func testFetchWatchlist() {
        let fetcher = WKWatchlistFetcher()
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WKWatchlist?
        fetcher.fetchWatchlist { result in
            switch result {
            case .success(let watchlist):
                
                watchlistToTest = watchlist
                
            case .failure(let error):
                XCTFail("Failure fetching watchlist: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        guard let watchlistToTest else {
            XCTFail("Missing watchlistToTest")
            return
        }
        
        XCTAssertEqual(watchlistToTest.items.count, 51, "Incorrect number of watchlist items returned")
        
        let enItems = watchlistToTest.items.filter { $0.project == enProject }
        let esItems = watchlistToTest.items.filter { $0.project == esProject }
        
        XCTAssertEqual(enItems.count, 38, "Incorrect number of EN watchlist items returned")
        XCTAssertEqual(esItems.count, 13, "Incorrect number of ES watchlist items returned")
        
        let first = watchlistToTest.items.first!
        XCTAssertEqual(first.title, "Talk:Cat", "Unexpected watchlist item title property")
        XCTAssertEqual(first.username, "CatLover 1137", "Unexpected watchlist item username property")
        XCTAssertEqual(first.revisionID, 1157699533, "Unexpected watchlist item revisionID property")
        XCTAssertEqual(first.oldRevisionID, 1157699360, "Unexpected watchlist item oldRevisionID property")
        XCTAssertEqual(first.isAnon, false, "Unexpected watchlist item isAnon property")
        XCTAssertEqual(first.isBot, false, "Unexpected watchlist item isBot property")
        XCTAssertEqual(first.commentHtml, "<span dir=\"auto\"><span class=\"autocomment\"><a href=\"/wiki/Talk:Cat#I_disagree_with_the_above_comment\" title=\"Talk:Cat\">→‎I disagree with the above comment</a>: </span> Reply</span>", "Unexpected watchlist item commentHtml property")
        XCTAssertEqual(first.project, WKProject.wikipedia(WKLanguage(languageCode: "en", languageVariantCode: nil)))
        
        var dateComponents = DateComponents()
        dateComponents.year = 2023
        dateComponents.month = 5
        dateComponents.day = 30
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        dateComponents.hour = 11
        dateComponents.minute = 37
        dateComponents.second = 31
        
        guard let testDate = Calendar.current.date(from: dateComponents) else {
            XCTFail("Failure creating testDate")
            return
        }
        
        XCTAssertEqual(first.timestamp, testDate, "Unexpected watchlist item timestamp property")
    }
}
