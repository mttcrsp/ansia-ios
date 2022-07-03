@testable
import App
import SnapshotTesting
import XCTest

final class LoadingViewControllerTests: XCTestCase {
  func testConfiguration() {
    let vc = LoadingViewController()
    vc.view.backgroundColor = .systemBackground
    assertSnapshot(matching: vc, as: .image(on: .iPhone12))
  }
}
