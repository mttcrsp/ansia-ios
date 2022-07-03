@testable
import App
import Core
import SnapshotTesting
import XCTest

final class SettingsRegionViewControllerTests: XCTestCase {
  func testConfigurations() {
    let feed1 = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "Sport", collection: "2", emoji: "2", weight: 2)
    let feeds = [feed1, feed2]

    let configurations: [RegionsConfiguration] = [
      .init(feeds: feeds),
      .init(feeds: feeds, selectedFeed: feed2),
    ]

    for configuration in configurations {
      let vc = SettingsRegionViewController()
      let nc = UINavigationController(rootViewController: vc)
      vc.configuration = configuration
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }
}
