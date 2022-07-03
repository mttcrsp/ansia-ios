@testable
import App
import ComposableArchitecture
import Core
import HammerTests
import SnapshotTesting
import XCTest

final class TodayViewControllerTests: XCTestCase {
  private typealias Action = TodayReducer.Action
  private typealias State = TodayReducer.State

  func testStates() throws {
    let state = TodayReducer.State(
      groups: .init(
        home: .init(
          articles: [Article](repeating: article1, count: 4)
        ),
        region: .init(
          feed: feeds.first,
          articles: [Article](repeating: article2, count: 6)
        ),
        sections: feeds.suffix(3).map { feed in
          .init(
            feed: feed,
            articles: [Article](repeating: article2, count: 4)
          )
        }
      ),
      video: video
    )

    let store = Store(initialState: state, reducer: TodayReducer())
    let vc = TodayViewController(store: store)
    let nc = UINavigationController(rootViewController: vc)
    vc.node.recursivelyEnsureDisplaySynchronously(true)
    vc.node.waitUntilAllUpdatesAreProcessed()
    vc.node.recursivelyEnsureDisplaySynchronously(true)
    assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    assertSnapshot(matching: vc, as: .image(on: .init(size: vc.node.view.contentSize)))
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

private let video: Video = {
  let responseData = try! Data(contentsOf: Files.videosJson.url)
  let response = try! JSONDecoder.default.decode(VideosRequest.Response.self, from: responseData)
  let video = try! XCTUnwrap(response.videos.first)
  return video
}()
