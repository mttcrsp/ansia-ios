import Core
import XCTest

final class OnboardingClientTests: XCTestCase {
  private var onboardingClient: OnboardingClient!
  private var userDefaults: UserDefaults!
  private let userDefaultsSuite = "com.mttcrsp.ansia.onboardingClientTests"

  override func setUpWithError() throws {
    try super.setUpWithError()
    let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuite))
    self.userDefaults = userDefaults
    self.userDefaults.removePersistentDomain(forName: userDefaultsSuite)
    onboardingClient = .init(userDefaults: userDefaults)
  }

  func testDidCompleteOnboarding() throws {
    XCTAssertFalse(onboardingClient.didCompleteOnboarding())
    onboardingClient.setDidCompleteOnboarding()
    XCTAssertTrue(onboardingClient.didCompleteOnboarding())
  }

  func testDidCompleteRegionOnboarding() {
    XCTAssertFalse(onboardingClient.didCompleteRegionOnboarding())
    onboardingClient.setDidCompleteRegionOnboarding()
    XCTAssertTrue(onboardingClient.didCompleteRegionOnboarding())
  }

  func testDidCompleteVideoOnboarding() {
    XCTAssertFalse(onboardingClient.didCompleteVideoOnboarding())
    onboardingClient.setDidCompleteVideoOnboarding()
    XCTAssertTrue(onboardingClient.didCompleteVideoOnboarding())
  }

  func testDidWatchVideo() {
    XCTAssertFalse(onboardingClient.didWatchVideo())
    onboardingClient.setDidWatchVideo()
    XCTAssertTrue(onboardingClient.didWatchVideo())
  }
}
