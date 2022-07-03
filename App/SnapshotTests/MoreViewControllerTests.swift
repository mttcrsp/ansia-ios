@testable
import App
import ComposableArchitecture
import Core
import HammerTests
import SnapshotTesting
import XCTest

@MainActor
final class MoreViewControllerTests: XCTestCase {
  func testStates() throws {
    let bookmark = Bookmark(article: article1, createdAt: .init())
    let recents = Recent(article: article2, createdAt: .init())

    let states: [MoreReducer.State] = [
      .init(
        bookmarks: [Bookmark](repeating: bookmark, count: 6),
        feeds: feeds,
        recents: [Recent](repeating: recents, count: 6)
      ),
      .init(
        bookmarks: [Bookmark](repeating: bookmark, count: 3),
        feeds: Array(feeds.prefix(upTo: 3))
      ),
      .init(
        feeds: Array(feeds.prefix(upTo: 1)),
        recents: [Recent](repeating: recents, count: 2)
      ),
    ]

    for state in states {
      let store = Store(initialState: state, reducer: MoreReducer())
      let vc = MoreViewController(store: store)
      let nc = UINavigationController(rootViewController: vc)
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      vc.node.waitUntilAllUpdatesAreProcessed()
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }
}

private let article1: Article = {
  let articleData = try! Data(contentsOf: Files.articleJson.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()

private let article2: Article = {
  let articleData = try! Data(contentsOf: Files.article2Json.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()

private let feeds: [Feed] = {
  let responseData = try! Data(contentsOf: Files.feedsJson.url)
  let response = try! JSONDecoder.default.decode(FeedsRequest.Response.self, from: responseData)
  return response.feeds
}()
