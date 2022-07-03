@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class NotificationsReducerTests: XCTestCase {
  func testLoading() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    let applicationState = AsyncStream<ApplicationStateChange>.streamWithContinuation()
    var observeApplicationStateCalled = false
    store.dependencies.applicationStateClient.observe = {
      observeApplicationStateCalled = true
      return applicationState.stream
    }

    let task = await store.send(.didLoad)
    await store.receive(.notificationsStatusChanged(.disabled))

    let change = ApplicationStateChange(from: .foreground, to: .background, duration: 1)
    applicationState.continuation.yield(change)
    await store.receive(.applicationStateChanged(change))

    await store.send(.didUnload).finish()
    await task.finish()
    XCTAssertTrue(observeApplicationStateCalled)
  }

  func testApplicationStateChangedToBackground() async {
    let store = TestStore(initialState: .init(shouldReload: true), reducer: NotificationsReducer())

    let applicationStateChange = ApplicationStateChange(from: .foreground, to: .background, duration: 1)
    await store.send(.applicationStateChanged(applicationStateChange)).finish()
  }

  func testApplicationStateChangedToForeground() async {
    let store = TestStore(initialState: .init(shouldReload: true), reducer: NotificationsReducer())

    let applicationStateChange = ApplicationStateChange(from: .background, to: .foreground, duration: 1)
    await store.send(.applicationStateChanged(applicationStateChange)).finish()
    await store.receive(.shouldReloadChanged(false)) { state in
      state.shouldReload = false
    }
    await store.receive(.notificationsStatusChanged(.disabled))
    await store.receive(.shouldReloadChanged(true)) { state in
      state.shouldReload = true
    }
  }

  func testVideoDayToggledOn() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var request: NotificationsServiceRequest?
    store.dependencies.notificationsClient.addRequest = { value in
      request = value
    }

    await store.send(.videoDayToggled(true)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(request as? VideoNotificationRequest, .day)
  }

  func testVideoDayToggledOff() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var request: NotificationsServiceRequest?
    store.dependencies.notificationsClient.removeRequest = { value in
      request = value
    }

    await store.send(.videoDayToggled(false)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(request as? VideoNotificationRequest, .day)
  }

  func testVideoNightToggledOn() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var request: NotificationsServiceRequest?
    store.dependencies.notificationsClient.addRequest = { value in
      request = value
    }

    await store.send(.videoNightToggled(true)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(request as? VideoNotificationRequest, .night)
  }

  func testVideoNightToggledOff() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var request: NotificationsServiceRequest?
    store.dependencies.notificationsClient.removeRequest = { value in
      request = value
    }

    await store.send(.videoNightToggled(false)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(request as? VideoNotificationRequest, .night)
  }

  func testAllNotificationsToggledOff() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var didRemoveAllRequests = false
    store.dependencies.notificationsClient.removeAllRequests = {
      didRemoveAllRequests = true
    }

    var didDisableNotifications = false
    store.dependencies.preferencesClient.setNotificationsDisabled = { value in
      didDisableNotifications = value
    }
    store.dependencies.preferencesClient.areNotificationsDisabled = {
      didDisableNotifications
    }

    await store.send(.allNotificationsToggled(false)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertTrue(didRemoveAllRequests)
    XCTAssertEqual(didDisableNotifications, true)
  }

  func testAllNotificationsToggledOnOnboading() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var didDisableNotifications: Bool?
    store.dependencies.preferencesClient.setNotificationsDisabled = { value in
      didDisableNotifications = value
    }

    store.dependencies.notificationsClient.isAuthorized = { false }
    store.dependencies.notificationsClient.canRequestAuthorization = { true }

    var requestAuthorizationCalled = false
    store.dependencies.notificationsClient.requestAuthorization = {
      requestAuthorizationCalled = true
      return true
    }

    await store.send(.allNotificationsToggled(true)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(didDisableNotifications, false)
    XCTAssertTrue(requestAuthorizationCalled)
  }

  func testAllNotificationsToggledOnReboading() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var didDisableNotifications: Bool?
    store.dependencies.preferencesClient.setNotificationsDisabled = { value in
      didDisableNotifications = value
    }

    store.dependencies.notificationsClient.isAuthorized = { false }
    store.dependencies.notificationsClient.canRequestAuthorization = { false }

    var openNotificationSettingsCalled = false
    store.dependencies.applicationOpenClient.openNotificationSettings = {
      openNotificationSettingsCalled = true
    }

    await store.send(.allNotificationsToggled(true)).finish()
    await store.receive(.notificationsStatusChanged(.disabled))
    XCTAssertEqual(didDisableNotifications, false)
    XCTAssertTrue(openNotificationSettingsCalled)
  }

  func testAllNotificationsToggledOnAlreadyAuthorized() async {
    let store = TestStore(initialState: .init(), reducer: NotificationsReducer())

    var didDisableNotifications: Bool?
    store.dependencies.preferencesClient.setNotificationsDisabled = { value in
      didDisableNotifications = value
    }

    store.dependencies.notificationsClient.isAuthorized = { true }

    var openNotificationSettingsCalled = false
    store.dependencies.applicationOpenClient.openNotificationSettings = {
      openNotificationSettingsCalled = true
    }

    var requestAuthorizationCalled = false
    store.dependencies.notificationsClient.requestAuthorization = {
      requestAuthorizationCalled = true
      return true
    }

    let status = NotificationsStatus.enabled(.init())
    await store.send(.allNotificationsToggled(true)).finish()
    await store.receive(.notificationsStatusChanged(status)) { state in
      state.notificationsStatus = status
    }
    XCTAssertEqual(didDisableNotifications, false)
    XCTAssertFalse(openNotificationSettingsCalled)
    XCTAssertFalse(requestAuthorizationCalled)
  }
}
