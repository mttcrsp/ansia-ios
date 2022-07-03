@testable
import App
import AsyncDisplayKit
import ComposableArchitecture
import Core
import HammerTests
import SnapshotTesting
import XCTest

final class ArticleViewControllerTests: XCTestCase {
  private typealias Action = ArticleReducer.Action
  private typealias State = ArticleReducer.State

  func testStates() throws {
    let states: [State] = [
      .init(article: article),
      .init(article: article, showsBookmark: true),
    ]

    for state in states {
      let reducer = ArticleReducer().transformDependency(\.self) {
        $0.date = .constant(article.publishedAt.addingTimeInterval(-6000))
      }

      let store = Store(initialState: state, reducer: reducer)
      let vc = ArticleViewController(store: store)
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      let nc = UINavigationController(rootViewController: vc)
      let generator = try EventGenerator(viewController: nc)
      try generator.waitUntilVisible("published_label", timeout: 1)

      for node in vc.node.subnodes ?? [] {
        node.didEnterVisibleState()
        node.recursivelyEnsureDisplaySynchronously(true)
      }

      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }

  func testEvents() throws {
    var actions: [Action] = []

    let date = Date()
    let reducer = Reduce<State, Action> { _, action in
      actions.append(action)
      return .none
    }
    .transformDependency(\.self) {
      $0.date = .constant(date)
    }

    let state = State(article: article)
    let store = Store(initialState: state, reducer: reducer)
    let vc = ArticleViewController(store: store)
    let nc = UINavigationController(rootViewController: vc)
    let generator = try EventGenerator(viewController: nc)
    try generator.waitUntilHittable("bookmark_button", timeout: 1)
    try generator.fingerTap(at: "bookmark_button")

    XCTAssertEqual(actions, [
      .didLoad,
      .didAppear,
      .bookmarkStatusToggled,
    ])
  }
}

private let article: Article = {
  let articleData = try! Data(contentsOf: Files.articleJson.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()
