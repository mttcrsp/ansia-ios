import ComposableArchitecture
import Core

struct PersistenceClient {
  var deleteBookmark: (Article.ID) async throws -> Void
  var getArticles: (Feed.Slug, Int) async throws -> [Article]
  var getBookmarks: (Int, Int) async throws -> [Bookmark]
  var getFeed: (Feed.Slug) async throws -> Feed?
  var getFeeds: ([Feed.Slug]) async throws -> [Feed]
  var getFeedsByCollection: (Feed.Collection) async throws -> [Feed]
  var getPath: () -> String?
  var insertBookmark: (Bookmark) async throws -> Void
  var load: (String?) throws -> Void
  var observeArticles: (Feed.Slug, Int) -> AsyncThrowingStream<[Article], Error>
  var observeBookmark: (Article.ID) -> AsyncThrowingStream<Bookmark?, Error>
  var observeBookmarks: (Int, Int) -> AsyncThrowingStream<[Bookmark], Error>
  var observeFeeds: ([Feed.Slug]) -> AsyncThrowingStream<[Feed], Error>
  var observeFeedsByCollection: (Feed.Collection) -> AsyncThrowingStream<[Feed], Error>
  var observeRecents: (Int) -> AsyncThrowingStream<[Recent], Error>
  var updateFeeds: ([Feed]) async throws -> Void
  var upsertRecent: (Recent) async throws -> Void
}

extension PersistenceClient: DependencyKey {
  public static let liveValue: PersistenceClient = {
    let service = PersistenceServiceLive.shared
    return PersistenceClient(
      deleteBookmark: { articleID in try await service.perform(DeleteBookmark(articleID: articleID)) },
      getArticles: { slug, limit in try await service.perform(GetArticlesByFeed(slug: slug, limit: limit)) },
      getBookmarks: { limit, offset in try await service.perform(GetBookmarks(limit: limit, offset: offset)) },
      getFeed: { slug in try await service.perform(GetFeedBySlug(slug: slug)) },
      getFeeds: { slugs in try await service.perform(GetFeedsBySlugs(slugs: slugs)) },
      getFeedsByCollection: { collection in try await service.perform(GetFeedsByCollection(collection: collection)) },
      getPath: { service.path },
      insertBookmark: { bookmark in try await service.perform(InsertBookmark(bookmark: bookmark)) },
      load: { path in try service.load(at: path) },
      observeArticles: { slug, limit in service.observe(GetArticlesByFeed(slug: slug, limit: limit)) },
      observeBookmark: { articleID in service.observe(GetBookmark(articleID: articleID)) },
      observeBookmarks: { limit, offset in service.observe(GetBookmarks(limit: limit, offset: offset)) },
      observeFeeds: { slugs in service.observe(GetFeedsBySlugs(slugs: slugs)) },
      observeFeedsByCollection: { collection in service.observe(GetFeedsByCollection(collection: collection)) },
      observeRecents: { limit in service.observe(GetRecents(limit: limit)) },
      updateFeeds: { feeds in try await service.perform(UpdateFeeds(feeds: feeds)) },
      upsertRecent: { recent in try await service.perform(UpsertRecent(recent: recent)) }
    )
  }()

  #if DEBUG
  static let testValue = PersistenceClient(
    deleteBookmark: { _ in },
    getArticles: { _, _ in [] },
    getBookmarks: { _, _ in [] },
    getFeed: { _ in nil },
    getFeeds: { _ in [] },
    getFeedsByCollection: { _ in [] },
    getPath: { nil },
    insertBookmark: { _ in },
    load: { _ in },
    observeArticles: { _, _ in AsyncThrowingStream { $0.finish() } },
    observeBookmark: { _ in AsyncThrowingStream { $0.finish() } },
    observeBookmarks: { _, _ in AsyncThrowingStream { $0.finish() } },
    observeFeeds: { _ in AsyncThrowingStream { $0.finish() } },
    observeFeedsByCollection: { _ in AsyncThrowingStream { $0.finish() } },
    observeRecents: { _ in AsyncThrowingStream { $0.finish() } },
    updateFeeds: { _ in },
    upsertRecent: { _ in }
  )
  #endif
}

extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}

extension PersistenceServiceLive {
  static let shared: PersistenceService = PersistenceServiceLive(
    migrations: [
      CreateArticlesTable(),
      CreateFeedsTable(),
      CreateBookmarksTable(),
      CreateRecentsTable(),
    ]
  )
}
