@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class MoreReducerTests: XCTestCase {
  func testDidLoad() async {
    let date = Date()
    let bookmark = Bookmark(article: article, createdAt: date)
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let recent = Recent(article: article, createdAt: date)
    let store = TestStore(initialState: .init(), reducer: MoreReducer())

    var bookmarksLimit: Int?, bookmarksOffset: Int?
    let bookmarks = AsyncThrowingStream<[Bookmark], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeBookmarks = { value1, value2 in
      bookmarksLimit = value1
      bookmarksOffset = value2
      return bookmarks.stream
    }

    var recentsLimit: Int?
    let recents = AsyncThrowingStream<[Recent], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeRecents = { value in
      recentsLimit = value
      return recents.stream
    }

    var collection: Feed.Collection?
    let feeds = AsyncThrowingStream<[Feed], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeFeedsByCollection = { value in
      collection = value
      return feeds.stream
    }

    let task = await store.send(.didLoad)

    bookmarks.continuation.yield([bookmark])
    await store.receive(.bookmarksChanged([bookmark])) { state in
      state.bookmarks = [bookmark]
    }

    recents.continuation.yield([recent])
    await store.receive(.recentsChanged([recent])) { state in
      state.recents = [recent]
    }

    feeds.continuation.yield([feed])
    await store.receive(.feedsChanged([feed])) { state in
      state.feeds = [feed]
    }

    await store.send(.didUnload).finish()
    await task.finish()

    XCTAssertEqual(collection, .main)
    XCTAssertEqual(bookmarksLimit, 100)
    XCTAssertEqual(bookmarksOffset, 0)
    XCTAssertEqual(recentsLimit, 100)
  }

  func testSectionSelected() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(), reducer: MoreReducer())

    var slugs: [Feed.Slug]?
    store.dependencies.feedsClient.loadArticles = { value in
      slugs = value
    }

    var articlesSlug: Feed.Slug?, articlesLimit: Int?
    let articles = AsyncThrowingStream<[Article], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeArticles = { value1, value2 in
      articlesSlug = value1
      articlesLimit = value2
      return articles.stream
    }

    let task = await store.send(.sectionSelected(feed))

    articles.continuation.yield([article])
    await store.receive(.sectionArticlesChanged([article])) { state in
      state.sectionArticles = [article]
    }

    await store.send(.sectionDeselected) { state in
      state.sectionArticles = []
    }.finish()
    await task.finish()

    XCTAssertEqual(articlesSlug, feed.slug)
    XCTAssertEqual(articlesLimit, 30)
    XCTAssertEqual(slugs, [feed.slug])
  }

  func testArticleSelected() async {
    let store = TestStore(initialState: .init(), reducer: MoreReducer())

    await store.send(.articleSelected(article)) { state in
      state.article = .init(article: article)
    }.finish()

    await store.send(.article(.didUnload)) { state in
      state.article = nil
    }.finish()
  }

  func testQueryChanged() async {
    let clock = TestClock()
    let store = TestStore(initialState: .init(resultsArticles: [article]), reducer: MoreReducer())
    store.dependencies.continuousClock = clock

    var query: String?
    store.dependencies.networkClient.getItems = { value in
      query = value
      return [article]
    }

    let task1 = await store.send(.queryChanged("  something  ")) { state in
      state.resultsArticles = nil
      state.query = "something"
    }

    await clock.advance(by: .seconds(0.2))

    let task2 = await store.send(.queryChanged("  else  ")) { state in
      state.resultsArticles = nil
      state.query = "else"
    }

    await task1.finish()
    await clock.advance(by: .seconds(0.5))
    await task2.finish()
    await store.receive(.resultsArticlesChanged([article])) { state in
      state.resultsArticles = [article]
    }

    XCTAssertEqual(query, "else")
  }

  func testQueryChangedTooShort() async {
    let store = TestStore(initialState: .init(), reducer: MoreReducer())
    await store.send(.queryChanged("   so  ")).finish()
  }

  func testQueryChangedSameQuery() async {
    let store = TestStore(initialState: .init(query: "something"), reducer: MoreReducer())
    await store.send(.queryChanged("  something  ")).finish()
  }
}

private let article: Article = {
  let articleData = try! Data(contentsOf: Files.articleJson.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()
