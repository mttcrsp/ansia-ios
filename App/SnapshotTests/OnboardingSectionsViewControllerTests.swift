@testable
import App
import Core
import HammerTests
import SnapshotTesting
import XCTest

final class OnboardingSectionsViewControllerTests: XCTestCase {
  func testConfiguration() {
    let configurations: [SectionsConfiguration] = [
      .init(feeds: feeds),
      .init(feeds: feeds, selectedFeeds: [feeds[1], feeds[3]]),
    ]

    for configuration in configurations {
      let vc = OnboardingSectionsViewController(configuration: configuration)
      let nc = UINavigationController(rootViewController: vc)
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }

  func testEvents() throws {
    let vc = OnboardingSectionsViewController(configuration: .init(feeds: feeds))

    var didTapConfirm = false
    vc.onConfirmTap = {
      didTapConfirm = true
    }

    let generator = try EventGenerator(viewController: vc)
    try generator.fingerTap(at: "confirm_button")
    XCTAssertTrue(didTapConfirm)
  }
}

private let feeds: [Feed] = {
  let responseData = try! Data(contentsOf: Files.feedsJson.url)
  let response = try! JSONDecoder.default.decode(FeedsRequest.Response.self, from: responseData)
  return response.feeds
}()
