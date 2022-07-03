import Core
import XCTest

final class PreferencesClientTests: XCTestCase {
  private var preferencesClient: PreferencesClient!
  private var userDefaults: UserDefaults!
  private let userDefaultsSuite = "com.mttcrsp.ansia.preferencesServiceTests"

  override func setUp() {
    super.setUp()
    userDefaults = .init(suiteName: userDefaultsSuite)!
    userDefaults.removePersistentDomain(forName: userDefaultsSuite)
    preferencesClient = .init(userDefaults: userDefaults)
  }

  func testDidDisableNotifications() throws {
    XCTAssertFalse(preferencesClient.areNotificationsDisabled())
    preferencesClient.setNotificationsDisabled(true)
    XCTAssertTrue(preferencesClient.areNotificationsDisabled())
  }
}
