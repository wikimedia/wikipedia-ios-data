import XCTest
@testable import WKData
@testable import WKDataMocks

final class WKWatchlistServiceTests: XCTestCase {
    
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
        let service = WKWatchlistService()
        
        let expectation = XCTestExpectation(description: "Fetch Watchlist")
        
        var watchlistToTest: WKWatchlist?
        service.fetchWatchlist { result in
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
        
        XCTAssertEqual(watchlistToTest.items.count, 82, "Incorrect number of watchlist items returned")
        
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
        XCTAssertEqual(first.commentWikitext, "/* I disagree with the above comment */ Reply", "Unexpected watchlist item commentWikitext property")
        XCTAssertEqual(first.commentHtml, "<span dir=\"auto\"><span class=\"autocomment\"><a href=\"/wiki/Talk:Cat#I_disagree_with_the_above_comment\" title=\"Talk:Cat\">→‎I disagree with the above comment</a>: </span> Reply</span>", "Unexpected watchlist item commentHtml property")
        XCTAssertEqual(first.byteLength, 4246, "Unexpected watchlist item byteLength property")
        XCTAssertEqual(first.oldByteLength, 4071, "Unexpected watchlist item oldByteLength property")
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
    
    func testPostWatchArticleExpiryNever() {
         let service = WKWatchlistService()

         let expectation = XCTestExpectation(description: "Post Watch Article Expiry Never")

         var resultToTest: Result<Void, Error>?
        service.watch(title: "Cat", project: enProject, expiry: .never) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success(_) = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }

     func testPostWatchArticleExpiryDate() {
         let service = WKWatchlistService()

         let expectation = XCTestExpectation(description: "Post Watch Article Expiry Date")

         var resultToTest: Result<Void, Error>?
         service.watch(title: "Cat", project: enProject, expiry: .oneMonth) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success(_) = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }

     func testPostUnwatchArticle() {
         let service = WKWatchlistService()

         let expectation = XCTestExpectation(description: "Post Watch Unwatch Article")

         var resultToTest: Result<Void, Error>?
         service.unwatch(title: "Cat", project: enProject) { result in
             resultToTest = result
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 10.0)

         guard case .success(_) = resultToTest else {
             return XCTFail("Unexpected result")
         }
     }
    
    func testFetchWatchStatus() {
         let service = WKWatchlistService()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
         var statusToTest: WKPageWatchStatus?
        service.fetchWatchStatus(title: "Cat", project: enProject) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertTrue(statusToTest.watched)
         XCTAssertNil(statusToTest.userHasRollbackRights)
     }

     func testFetchWatchStatusWithRollbackRights() {
         let service = WKWatchlistService()

         let expectation = XCTestExpectation(description: "Fetch Watch Status")
         var statusToTest: WKPageWatchStatus?
         service.fetchWatchStatus(title: "Cat", project: enProject, needsRollbackRights: true) { result in
             switch result {
             case .success(let status):
                 statusToTest = status
             case .failure(let error):
                 XCTFail("Failure fetching watch status: \(error)")
             }
             expectation.fulfill()
         }

         guard let statusToTest else {
             XCTFail("Missing statusToTest")
             return
         }

         XCTAssertFalse(statusToTest.watched)
         XCTAssertTrue((statusToTest.userHasRollbackRights ?? false))
     }
    
    func testPostRollbackArticle() {
        let service = WKWatchlistService()

        let expectation = XCTestExpectation(description: "Post Rollback Article")

        var resultToTest: Result<WKUndoOrRollbackResult, Error>?
        service.rollback(title: "Cat", project: enProject, username: "Amigao") { result in
            resultToTest = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        guard let resultToTest else {
            return XCTFail("Unexpected result")
        }
        
        switch resultToTest {
        case .success(let result):
            XCTAssertEqual(result.newRevisionID, 573955)
            XCTAssertEqual(result.oldRevisionID, 573953)
        case .failure:
            return XCTFail("Unexpected result")
        }
    }
    
    func testPostUndoArticle() {
        let service = WKWatchlistService()
        
        let expectation = XCTestExpectation(description: "Post Undo Article")

        var resultToTest: Result<WKUndoOrRollbackResult, Error>?
        service.undo(title: "Cat", revisionID: 1155871225, summary: "Testing", username: "Amigao", project: enProject) { result in
            resultToTest = result
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
        
        guard let resultToTest else {
            return XCTFail("Unexpected result")
        }
        
        switch resultToTest {
        case .success(let result):
            XCTAssertEqual(result.newRevisionID, 573989)
            XCTAssertEqual(result.oldRevisionID, 573988)
        case .failure:
            return XCTFail("Unexpected result")
        }
    }
}
