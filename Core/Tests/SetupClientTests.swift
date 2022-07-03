import Core
import XCTest

final class SetupClientTests: XCTestCase {
  private var fileManager: FileManagerProtocolMock!
  private var networkService: NetworkServiceMock!
  private var persistenceService: PersistenceServiceMock!
  private var setupClient: SetupClient!

  override func setUp() {
    super.setUp()
    fileManager = .init()
    networkService = .init()
    persistenceService = .init()
    setupClient = .init(
      fileManager: fileManager,
      networkService: networkService,
      persistenceService: persistenceService
    )
  }

  func testPerform() async throws {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    persistenceService.performSyncReadHandler = { _ in [feed] }

    let url = try XCTUnwrap(URL(string: "/test"))
    fileManager.urlHandler = { _, _, _, _ in url }

    try await setupClient.perform()
    XCTAssertEqual(persistenceService.loadArgValues, ["/test/db.sqlite"])

    let args1 = persistenceService.performSyncReadArgValues as? [GetFeedsByCollection]
    let args2 = [GetFeedsByCollection(collection: .main)]
    XCTAssertEqual(args1, args2)

    XCTAssertEqual(networkService.performCallCount, 0)
    XCTAssertEqual(persistenceService.performWriteCallCount, 0)
  }

  func testPerformNoContent() async throws {
    let url = try XCTUnwrap(URL(string: "/test"))
    fileManager.urlHandler = { _, _, _, _ in url }
    persistenceService.performSyncReadHandler = { _ in [] }

    let responseData = try Data(contentsOf: Files.feedsJson.url)
    let response = try JSONDecoder.default.decode(FeedsRequest.Response.self, from: responseData)
    networkService.performHandler = { _ in response }

    try await setupClient.perform()
    XCTAssertEqual(persistenceService.loadCallCount, 1)

    let readArgs1 = persistenceService.performSyncReadArgValues as? [GetFeedsByCollection]
    let readArgs2 = [GetFeedsByCollection(collection: .main)]
    XCTAssertEqual(readArgs1, readArgs2)

    let feedsArgs1 = networkService.performArgValues as? [FeedsRequest]
    let feedsArgs2 = [FeedsRequest()]
    XCTAssertEqual(feedsArgs1, feedsArgs2)

    let writeArgs1 = persistenceService.performWriteArgValues as? [UpdateFeeds]
    let writeArgs2 = [UpdateFeeds(feeds: response.feeds)]
    XCTAssertEqual(writeArgs1, writeArgs2)
  }

  func testPerformLoadError() async throws {
    let loadError = URLError(.dataNotAllowed)
    persistenceService.loadHandler = { _ in throw loadError }

    do {
      try await setupClient.perform()
      XCTFail()
    } catch {
      XCTAssertEqual(error as? URLError, loadError)
    }

    XCTAssertEqual(persistenceService.performSyncReadCallCount, 0)
  }

  func testPerformReadError() async throws {
    let url = try XCTUnwrap(URL(string: "/test"))
    fileManager.urlHandler = { _, _, _, _ in url }

    let readError = URLError(.dataNotAllowed)
    persistenceService.performSyncReadHandler = { _ in throw readError }

    do {
      try await setupClient.perform()
      XCTFail()
    } catch {
      XCTAssertEqual(error as? URLError, readError)
    }

    XCTAssertEqual(networkService.performCallCount, 0)
    XCTAssertEqual(persistenceService.performWriteCallCount, 0)
  }
}
