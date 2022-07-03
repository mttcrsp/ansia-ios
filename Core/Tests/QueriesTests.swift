import Core
import XCTest

final class QueriesTests: XCTestCase {
  var persistenceService: PersistenceServiceLive!

  override func setUp() async throws {
    try await super.setUp()
    let persistenceService = PersistenceServiceLive(migrations: [
      CreateArticlesTable(),
      CreateFeedsTable(),
      CreateBookmarksTable(),
      CreateRecentsTable(),
    ])
    try persistenceService.load(at: nil)
    self.persistenceService = persistenceService
  }

  func testInsertBookmark() throws {
    let articleData = try Data(contentsOf: Files.articleJson.url)
    let article = try JSONDecoder.default.decode(Article.self, from: articleData)

    let bookmark1 = Bookmark(article: article, createdAt: Date())
    let bookmarkWrite = InsertBookmark(bookmark: bookmark1)
    try persistenceService.performSync(bookmarkWrite)

    let bookmarksRead = GetBookmarks(limit: 10, offset: 0)
    let bookmarks1 = try persistenceService.performSync(bookmarksRead)
    XCTAssertEqual(bookmarks1.count, 1)
    XCTAssertEqual(bookmarks1.first?.article, bookmark1.article)

    let bookmarkRead = GetBookmark(articleID: article.articleID)
    let bookmark2 = try persistenceService.performSync(bookmarkRead)
    XCTAssertEqual(bookmark1.article, bookmark2?.article)

    let bookmarkDelete = DeleteBookmark(articleID: article.articleID)
    try persistenceService.performSync(bookmarkDelete)

    let bookmarks2 = try persistenceService.performSync(bookmarksRead)
    XCTAssertEqual(bookmarks2.count, 0)
  }

  func testRecent() throws {
    let article1Data = try Data(contentsOf: Files.articleJson.url)
    let article2Data = try Data(contentsOf: Files.article2Json.url)
    let article1 = try JSONDecoder.default.decode(Article.self, from: article1Data)
    let article2 = try JSONDecoder.default.decode(Article.self, from: article2Data)

    let recent1 = Recent(article: article1, createdAt: Date())
    let recent2 = Recent(article: article2, createdAt: Date().addingTimeInterval(60))
    for recent in [recent1, recent2, recent1] {
      let recentWrite = UpsertRecent(recent: recent)
      try persistenceService.performSync(recentWrite)
    }

    let recentsRead = GetRecents(limit: 10)
    let recents1 = try persistenceService.performSync(recentsRead)
    XCTAssertEqual(recents1.count, 2)
    XCTAssertEqual(recents1.first?.article, recent2.article)
    XCTAssertEqual(recents1.last?.article, recent1.article)

    let recentsDelete = DeleteRecents(maxCount: 1)
    try persistenceService.performSync(recentsDelete)

    let recents2 = try persistenceService.performSync(recentsRead)
    XCTAssertEqual(recents2.count, 1)
    XCTAssertEqual(recents2.first?.article, recent2.article)

    let recentDelete = DeleteRecent(articleID: article2.articleID)
    try persistenceService.performSync(recentDelete)

    let recents3 = try persistenceService.performSync(recentsRead)
    XCTAssertEqual(recents3.count, 0)
  }

  func testFeed() throws {
    let responseData = try Data(contentsOf: Files.feedsJson.url)
    let response = try JSONDecoder.default.decode(FeedsRequest.Response.self, from: responseData)
    let feeds = response.feeds

    let feedsWrite1 = UpdateFeeds(feeds: feeds)
    try persistenceService.performSync(feedsWrite1)

    let feeds1Read = GetFeedsByCollection(collection: .main)
    let feeds1 = try persistenceService.performSync(feeds1Read)
    XCTAssertEqual(feeds1.count, 11)
    XCTAssertEqual(Set(feeds1.map(\.collection)), [.main])
    XCTAssertEqual(feeds1.sorted { lhs, rhs in lhs.weight < rhs.weight }, feeds1)

    let feedRead = GetFeedBySlug(slug: .main)
    let feed = try persistenceService.performSync(feedRead)
    XCTAssertEqual(feed?.slug, .main)

    let feeds2Read = GetFeedsBySlugs(slugs: [.main])
    let feeds2 = try persistenceService.performSync(feeds2Read)
    XCTAssertEqual(feeds2, [feed])

    let feedsWrite2 = UpdateFeeds(feeds: Array(feeds.prefix(upTo: 1)))
    try persistenceService.performSync(feedsWrite2)

    let feeds3Read = GetFeedsByCollection(collection: .main)
    let feeds3 = try persistenceService.performSync(feeds3Read)
    XCTAssertEqual(feeds3.count, 1)
  }

  func testUpdateFeedsArticles() throws {
    let responseData = try Data(contentsOf: Files.articlesByFeedResponseJson.url)
    let response = try JSONDecoder.default.decode(ArticlesByFeedRequest.Response.self, from: responseData)

    let articlesWrite = UpdateFeedsArticles(feeds: ["tecnologia": response.articles])
    try persistenceService.performSync(articlesWrite)

    let articlesRead = GetArticlesByFeed(slug: "tecnologia", limit: 10)
    let articles = try persistenceService.performSync(articlesRead)
    XCTAssertEqual(articles, response.articles.reversed())
  }

  func testUpdateFeedArticles() throws {
    let responseData = try Data(contentsOf: Files.articlesByFeedResponseJson.url)
    let response = try JSONDecoder.default.decode(ArticlesByFeedRequest.Response.self, from: responseData)

    let articlesWrite = UpdateFeedArticles(slug: "tecnologia", articles: response.articles)
    try persistenceService.performSync(articlesWrite)

    let articlesRead = GetArticlesByFeed(slug: "tecnologia", limit: 10)
    let articles = try persistenceService.performSync(articlesRead)
    XCTAssertEqual(articles, response.articles.reversed())
  }
}
