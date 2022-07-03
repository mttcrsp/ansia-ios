@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class RootReducerTests: XCTestCase {
  func testDidLoad() async {
    let store = TestStore(initialState: .init(), reducer: RootReducer())

    var startMonitoringRecentsCalled = false
    store.dependencies.recentsClient.startMonitoring = {
      startMonitoringRecentsCalled = true
    }

    var performCalled = false
    store.dependencies.setupClient.perform = {
      performCalled = true
    }

    store.dependencies.onboardingClient.didCompleteOnboarding = { true }

    await store.send(.didLoad) { state in
      state.today = .init()
    }.finish()
    await store.receive(.setupCompleted(true)) { state in
      state.content = .success
    }
    XCTAssertTrue(startMonitoringRecentsCalled)
    XCTAssertTrue(performCalled)
  }

  func testDidLoadOnboardingAvailable() async {
    let store = TestStore(initialState: .init(), reducer: RootReducer())
    store.dependencies.onboardingClient.didCompleteOnboarding = { false }

    await store.send(.didLoad) { state in
      state.onboarding = .init()
    }.finish()
    await store.receive(.setupCompleted(true)) { state in
      state.content = .success
    }
  }

  func testDidLoadSetupFailure() async {
    let store = TestStore(initialState: .init(), reducer: RootReducer())
    store.dependencies.onboardingClient.didCompleteOnboarding = { false }
    store.dependencies.setupClient.perform = {
      throw NSError(domain: "test", code: 1)
    }

    await store.send(.didLoad) { state in
      state.onboarding = .init()
    }.finish()
    await store.receive(.setupCompleted(false)) { state in
      state.content = .failure
    }
  }

  func testSetupRetryTapped() async {
    let store = TestStore(initialState: .init(content: .failure), reducer: RootReducer())
    await store.send(.setupRetryTapped) { state in
      state.content = .loading
    }.finish()
    await store.receive(.setupCompleted(true)) { state in
      state.content = .success
    }
  }

  func testOnboardingDidComplete() async {
    let store = TestStore(initialState: .init(onboarding: .init()), reducer: RootReducer())
    await store.send(.onboarding(.didComplete)) { state in
      state.today = .init()
    }.finish()
  }

  func testSettingsTapped() async {
    let store = TestStore(initialState: .init(), reducer: RootReducer())
    await store.send(.more(.settingsTapped)) { state in
      state.settings = .init()
    }.finish()
  }

  func testSettingsDidUnload() async {
    let store = TestStore(initialState: .init(settings: .init()), reducer: RootReducer())
    await store.send(.settings(.didUnload)) { state in
      state.settings = nil
    }.finish()
  }

  func testNotificationsDidUnload() async {
    let store = TestStore(initialState: .init(notifications: .init()), reducer: RootReducer())
    await store.send(.notifications(.didUnload)) { state in
      state.notifications = nil
    }.finish()
  }

  func testNotificationsSelected() async {
    let store = TestStore(initialState: .init(settings: .init()), reducer: RootReducer())
    await store.send(.settings(.notificationsSelected)) { state in
      state.notifications = .init()
    }.finish()
  }
}
