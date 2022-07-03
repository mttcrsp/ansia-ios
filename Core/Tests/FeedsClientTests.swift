import Core
import XCTest

@MainActor
final class FeedsClientTests: XCTestCase {
  private var feedsClient: FeedsClient!
  private var networkService: NetworkServiceMock!
  private var persistenceService: PersistenceServiceMock!

  override func setUp() {
    super.setUp()
    networkService = .init()
    persistenceService = .init()
    feedsClient = .init(networkService: networkService, persistenceService: persistenceService)
  }

  func testLoadArticles() async throws {
    let responseData = try Data(contentsOf: Files.articlesByFeedResponseJson.url)
    let response = try JSONDecoder.default.decode(ArticlesByFeedRequest.Response.self, from: responseData)

    var requests: Set<ArticlesByFeedRequest> = []
    var writes: [UpdateFeedsArticles] = []

    networkService.performHandler = { value in
      if let request = value as? ArticlesByFeedRequest {
        requests.insert(request)
      }
      return response
    }

    persistenceService.performWriteHandler = { value in
      if let write = value as? UpdateFeedsArticles {
        writes.append(write)
      }
    }

    let slugs: [Feed.Slug] = [.main, .local]
    try await feedsClient.loadArticles(slugs)
    XCTAssertEqual(requests, Set(slugs.map(ArticlesByFeedRequest.init)))
    XCTAssertEqual(writes, [.init(feeds: [
      .main: response.articles,
      .local: response.articles,
    ])])
  }
}
