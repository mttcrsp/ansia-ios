@testable
import App
import Core
import HammerTests
import SnapshotTesting
import XCTest

final class RegionViewControllerTests: XCTestCase {
  func testConfigurations() {
    let configurations: [RegionsConfiguration] = [
      .init(feeds: feeds),
      .init(feeds: feeds, selectedFeed: feeds[2]),
    ]

    for configuration in configurations {
      let vc = RegionViewController(configuration: configuration)
      let nc = UINavigationController(rootViewController: vc)
      vc.node.recursivelyEnsureDisplaySynchronously(true)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }

  func testEvents() throws {
    var didTapConfirm = false
    var didTapDismiss = false

    let vc = RegionViewController(configuration: .init(feeds: feeds))
    let nc = UINavigationController(rootViewController: vc)
    vc.onConfirmTap = { didTapConfirm = true }
    vc.onDismissTap = { didTapDismiss = true }

    let generator = try EventGenerator(viewController: nc)
    try generator.fingerTap(at: "confirm_button")
    XCTAssertFalse(didTapConfirm)
    XCTAssertFalse(didTapDismiss)

    vc.configuration = .init(feeds: feeds, selectedFeed: feeds.first)
    try generator.fingerTap(at: "confirm_button")
    XCTAssertTrue(didTapConfirm)
    XCTAssertFalse(didTapDismiss)

    try generator.fingerTap(at: "dismiss_button")
    XCTAssertTrue(didTapConfirm)
    XCTAssertTrue(didTapDismiss)
  }
}

private let feeds: [Feed] = {
  let responseData = try! Data(contentsOf: Files.feedsJson.url)
  let response = try! JSONDecoder.default.decode(FeedsRequest.Response.self, from: responseData)
  return response.feeds
}()
