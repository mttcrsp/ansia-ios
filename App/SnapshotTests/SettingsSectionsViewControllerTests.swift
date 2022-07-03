@testable
import App
import Core
import SnapshotTesting
import XCTest

final class SettingsSectionsViewControllerTests: XCTestCase {
  func testConfigurations() {
    let feed1 = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "Sport", collection: "2", emoji: "2", weight: 2)
    let feed3 = Feed(slug: "3", title: "Cultura", collection: "3", emoji: "3", weight: 3)
    let feeds = [feed1, feed2, feed3]

    let configurations: [SectionsConfiguration] = [
      .init(feeds: feeds),
      .init(feeds: feeds, selectedFeeds: Set([feed1, feed3])),
    ]

    for configuration in configurations {
      let vc = SettingsSectionsViewController()
      let nc = UINavigationController(rootViewController: vc)
      vc.configuration = configuration
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }
}
