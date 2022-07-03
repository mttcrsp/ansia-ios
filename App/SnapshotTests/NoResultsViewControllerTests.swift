@testable
import App
import HammerTests
import SnapshotTesting
import XCTest

final class NoResultsViewControllerTests: XCTestCase {
  func testConfiguration() throws {
    let vc = NoResultsViewController()
    let generator = try EventGenerator(viewController: vc)
    try generator.waitUntilVisible("no_results", timeout: 1)
    assertSnapshot(matching: vc, as: .image(on: .iPhone12))
  }
}
