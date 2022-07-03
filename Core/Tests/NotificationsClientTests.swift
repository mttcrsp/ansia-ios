import Core
import XCTest

final class NotificationsClientTests: XCTestCase {
  private var center: NotificationsServiceCenterMock!
  private var notificationsClient: NotificationsClient!

  override func setUp() {
    super.setUp()
    center = .init()
    notificationsClient = .init(center: center)
  }

  func testRequestAuthorization() async throws {
    var options: UNAuthorizationOptions?
    center.requestAuthorizationHandler = { value, completion in
      options = value
      completion(true, nil)
    }

    let result = try await notificationsClient.requestAuthorization()
    XCTAssertTrue(result)
    XCTAssertEqual(options, [.alert, .sound, .badge])
  }

  func testRequestAuthorizationDenied() async throws {
    center.requestAuthorizationHandler = { _, completion in
      completion(false, nil)
    }

    let result = try await notificationsClient.requestAuthorization()
    XCTAssertFalse(result)
  }

  func testRequestAuthorizationError() async throws {
    let error = NSError(domain: "test", code: 1)
    center.requestAuthorizationHandler = { _, completion in
      completion(false, error)
    }

    do {
      _ = try await notificationsClient.requestAuthorization()
      XCTFail()
    } catch let value as NSError {
      XCTAssertEqual(value, error)
    }
  }

  func testHasRequest() async {
    center.pendingNotificationRequestsHandler = {
      ["something", "else"].map { identifier in
        UNNotificationRequest(identifier: identifier, content: .init(), trigger: nil)
      }
    }

    var request = Request(identifier: "else")
    var result = await notificationsClient.hasRequest(request)
    XCTAssertTrue(result)

    request = Request(identifier: "wow")
    result = await notificationsClient.hasRequest(request)
    XCTAssertFalse(result)
  }

  func testAddRequest() async throws {
    center.addHandler = { _, completion in
      completion?(nil)
    }

    let identifier = "identifier"
    let request = Request(identifier: identifier)
    try await notificationsClient.addRequest(request)

    XCTAssertEqual(center.addCallCount, 1)
    XCTAssertEqual(center.addArgValues.first?.identifier, identifier)
  }

  func testAddRequestError() async throws {
    let addError = UNError(.notificationsNotAllowed)
    center.addHandler = { _, completion in
      completion?(addError)
    }

    let identifier = "identifier"
    let request = Request(identifier: identifier)
    do {
      try await notificationsClient.addRequest(request)
      XCTFail()
    } catch {
      XCTAssertEqual(error as? UNError, addError)
    }
  }

  func testRemoveRequest() {
    let identifier = "identifier"
    let request = Request(identifier: identifier)
    notificationsClient.removeRequest(request)
    XCTAssertEqual(center.removeDeliveredNotificationsArgValues, [[identifier]])
    XCTAssertEqual(center.removePendingNotificationRequestsArgValues, [[identifier]])
  }

  func testRemoveAllRequest() {
    notificationsClient.removeAllRequests()
    XCTAssertEqual(center.removeAllDeliveredNotificationsCallCount, 1)
    XCTAssertEqual(center.removeAllPendingNotificationRequestsCallCount, 1)
  }

  private struct Request: NotificationsServiceRequest {
    let identifier: String
    let title = "title"
    let body = "body"
  }
}
