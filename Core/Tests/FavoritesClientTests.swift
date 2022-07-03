import Core
import XCTest

final class FavoritesClientTests: XCTestCase {
  private var userDefaults: UserDefaults!
  private var favoritesClient: FavoritesClient!

  override func setUp() {
    userDefaults = .init()
    favoritesClient = .init(userDefaults: userDefaults)
  }

  override func tearDown() {
    if let name = Bundle.main.bundleIdentifier {
      userDefaults.removePersistentDomain(forName: name)
    }
  }

  func testFavoriteRegion() {
    favoritesClient.setFavoriteRegion("lombardia")
    XCTAssertEqual(favoritesClient.favoriteRegion(), "lombardia")

    favoritesClient.setFavoriteRegion(nil)
    XCTAssertNil(favoritesClient.favoriteRegion())
  }

  func testFavoriteSections() {
    favoritesClient.setFavoriteSections(["mondo", "calcio"])
    XCTAssertEqual(favoritesClient.favoriteSections(), ["mondo", "calcio"])

    favoritesClient.setFavoriteSections([])
    XCTAssertEqual(favoritesClient.favoriteSections(), [])
  }

  func testObserveFavoriteRegion() async throws {
    Task.detached {
      self.favoritesClient.setFavoriteRegion("lombardia")
      self.favoritesClient.setFavoriteRegion(nil)
    }

    var values: [Feed.Slug?] = []
    for try await value in favoritesClient.observeFavoriteRegion() {
      values.append(value)
      if values.count == 2 {
        break
      }
    }

    XCTAssertEqual(values, ["lombardia", nil])
  }

  func testObserveFavoriteSections() async {
    Task.detached {
      self.favoritesClient.setFavoriteSections(["sport", "mondo"])
      self.favoritesClient.setFavoriteSections([])
      self.favoritesClient.setFavoriteSections(["tecnologia"])
    }

    var values: [[Feed.Slug]] = []
    for try await value in favoritesClient.observeFavoriteSections() {
      values.append(value)
      if values.count == 3 {
        break
      }
    }

    XCTAssertEqual(values, [["sport", "mondo"], [], ["tecnologia"]])
  }
}
