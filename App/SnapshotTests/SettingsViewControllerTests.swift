@testable
import App
import ComposableArchitecture
import Core
import SnapshotTesting
import XCTest

final class SettingsViewControllerTests: XCTestCase {
  func testStates() {
    let feed1 = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "Sport", collection: "2", emoji: "2", weight: 2)
    let feed3 = Feed(slug: "3", title: "Lombardia", collection: "3", emoji: "3", weight: 3)

    let states: [SettingsReducer.State] = [
      .init(
        applicationBuild: "1",
        applicationVersion: "1.0",
        favoriteSections: [],
        favoriteRegion: feed3
      ),
      .init(
        favoriteSections: [feed1]
      ),
      .init(
        favoriteSections: [feed1, feed2]
      ),
    ]

    for state in states {
      let store = Store(initialState: state, reducer: SettingsReducer())
      let vc = SettingsViewController(store: store)
      let nc = UINavigationController(rootViewController: vc)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }
}
