@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class ArticleReducerTests: XCTestCase {
  func testDidLoad() async {
    let store = makeStore()
    let bookmark = Bookmark(article: article, createdAt: Date())
    let articleID1 = store.state.article.articleID
    var articleID2: Article.ID?

    store.dependencies.persistenceClient.observeBookmark = { articleID in
      articleID2 = articleID
      return AsyncThrowingStream { continuation in
        continuation.yield(bookmark)
        continuation.yield(nil)
      }
    }

    let task = await store.send(.didLoad)
    await store.receive(.bookmarkStatusChanged(bookmark)) { state in
      state.showsBookmark = true
    }
    await store.receive(.bookmarkStatusChanged(nil)) { state in
      state.showsBookmark = false
    }
    await store.send(.didUnload).finish()
    await task.finish()
    XCTAssertEqual(articleID1, articleID2)
  }

  func testDidAppear() async {
    let store = makeStore()
    let createdAt = store.dependencies.date.now
    let recent1 = Recent(article: article, createdAt: createdAt)
    var recent2: Recent?
    store.dependencies.persistenceClient.upsertRecent = { recent in
      recent2 = recent
    }

    await store.send(.didAppear).finish()
    XCTAssertEqual(recent1, recent2)
  }

  func testBookmarkStatusToggleOn() async {
    let store = makeStore(showsBookmark: false)
    let createdAt = store.dependencies.date.now
    let bookmark1 = Bookmark(article: article, createdAt: createdAt)
    var bookmark2: Bookmark?
    store.dependencies.persistenceClient.insertBookmark = { bookmark in
      bookmark2 = bookmark
    }

    await store.send(.bookmarkStatusToggled).finish()
    XCTAssertEqual(bookmark1, bookmark2)
  }

  func testBookmarkStatusToggleOff() async {
    let store = makeStore(showsBookmark: true)
    let articleID1 = store.state.article.articleID
    var articleID2: Article.ID?
    store.dependencies.persistenceClient.deleteBookmark = { articleID in
      articleID2 = articleID
    }

    await store.send(.bookmarkStatusToggled).finish()
    XCTAssertEqual(articleID1, articleID2)
  }

  private func makeStore(showsBookmark: Bool = false) -> TestStore<ArticleReducer.State, ArticleReducer.Action, ArticleReducer.State, ArticleReducer.Action, Void> {
    let state = ArticleReducer.State(article: article, showsBookmark: showsBookmark)
    let store = TestStore(initialState: state, reducer: ArticleReducer())
    store.dependencies.date = .constant(Date())
    return store
  }
}

private let article: Article = {
  let articleData = try! Data(contentsOf: Files.articleJson.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()
