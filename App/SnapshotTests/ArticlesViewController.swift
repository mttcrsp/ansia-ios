@testable
import App
import ComposableArchitecture
import Core
import HammerTests
import SnapshotTesting
import XCTest

final class ArticlesViewControllerTests: XCTestCase {
  func testStyles() {
    let stylingBlocks: [ArticlesSectionController.StylingBlock] = [
      { _ in .default },
      { element in element.index == 0 ? .fullWidth : .large },
      { element in element.index == 0 ? .default : .largeText },
      { element in element.index == 0 ? .small : .text },
    ]

    for stylingBlocks in stylingBlocks {
      let vc = ArticlesViewController(configuration: .init(title: "something", articles: articles))
      vc.stylingBlock = stylingBlocks
      let nc = UINavigationController(rootViewController: vc)
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      vc.node.waitUntilAllUpdatesAreProcessed()
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }
}

let articles: [Article] = {
  let responseData = try! Data(contentsOf: Files.articlesByFeedResponseJson.url)
  let response = try! JSONDecoder.default.decode(ArticlesByFeedRequest.Response.self, from: responseData)
  return response.articles
}()
