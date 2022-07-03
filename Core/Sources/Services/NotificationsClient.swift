import UserNotifications

public protocol NotificationsServiceRequest {
  var identifier: String { get }
  var title: String { get }
  var body: String { get }
}

public protocol NotificationServiceCalendarRequest: NotificationsServiceRequest {
  var dateComponents: DateComponents { get }
  var repeats: Bool { get }
}

public enum NotificationServiceEvent {
  case didReceiveResponse(identifier: String)
}

/// @mockable
public protocol NotificationsServiceCenter: AnyObject {
  var delegate: UNUserNotificationCenterDelegate? { get set }
  func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
  func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void)
  func pendingNotificationRequests() async -> [UNNotificationRequest]
  func removeAllDeliveredNotifications()
  func removeAllPendingNotificationRequests()
  func removeDeliveredNotifications(withIdentifiers identifiers: [String])
  func removePendingNotificationRequests(withIdentifiers identifiers: [String])
  func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)
}

extension UNUserNotificationCenter: NotificationsServiceCenter {}

public struct NotificationsClient {
  public var requestAuthorization: () async throws -> Bool
  public var canRequestAuthorization: () async -> Bool
  public var isAuthorized: () async -> Bool
  public var hasRequest: (NotificationsServiceRequest) async -> Bool
  public var addRequest: (NotificationsServiceRequest) async throws -> Void
  public var removeRequest: (NotificationsServiceRequest) -> Void
  public var removeAllRequests: () -> Void
  public var observe: () -> AsyncStream<NotificationServiceEvent>

  public init(requestAuthorization: @escaping () -> Bool, canRequestAuthorization: @escaping () -> Bool, isAuthorized: @escaping () -> Bool, hasRequest: @escaping (NotificationsServiceRequest) -> Bool, addRequest: @escaping (NotificationsServiceRequest) -> Void, removeRequest: @escaping (NotificationsServiceRequest) -> Void, removeAllRequests: @escaping () -> Void, observe: @escaping () -> AsyncStream<NotificationServiceEvent>) {
    self.requestAuthorization = requestAuthorization
    self.canRequestAuthorization = canRequestAuthorization
    self.isAuthorized = isAuthorized
    self.hasRequest = hasRequest
    self.addRequest = addRequest
    self.removeRequest = removeRequest
    self.removeAllRequests = removeAllRequests
    self.observe = observe
  }
}

public extension NotificationsClient {
  init(center: NotificationsServiceCenter = UNUserNotificationCenter.current()) {
    requestAuthorization = {
      try await withCheckedThrowingContinuation { continuation in
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          if let error {
            continuation.resume(with: .failure(error))
          } else {
            continuation.resume(with: .success(granted))
          }
        }
      }
    }

    canRequestAuthorization = {
      await withCheckedContinuation { continuation in
        center.getNotificationSettings { settings in
          continuation.resume(returning: settings.authorizationStatus == .notDetermined)
        }
      }
    }

    isAuthorized = {
      await withCheckedContinuation { continuation in
        center.getNotificationSettings { settings in
          continuation.resume(returning: settings.authorizationStatus == .authorized)
        }
      }
    }

    hasRequest = { target in
      await center.pendingNotificationRequests().contains { request in
        request.identifier == target.identifier
      }
    }

    addRequest = { request in
      let content = UNMutableNotificationContent()
      content.title = request.title
      content.body = request.body

      let request = UNNotificationRequest(identifier: request.identifier, content: content, trigger: request.trigger)
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        center.add(request) { error in
          if let error {
            continuation.resume(with: .failure(error))
          } else {
            continuation.resume()
          }
        }
      }
    }

    removeRequest = { request in
      center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
      center.removePendingNotificationRequests(withIdentifiers: [request.identifier])
    }

    removeAllRequests = {
      center.removeAllDeliveredNotifications()
      center.removeAllPendingNotificationRequests()
    }

    observe = {
      .init { continuation in
        let delegate = Delegate(didReceive: continuation)
        center.delegate = delegate
        continuation.onTermination = { _ in _ = delegate }
      }
    }
  }
}

private final class Delegate: NSObject, UNUserNotificationCenterDelegate {
  let didReceive: AsyncStream<NotificationServiceEvent>.Continuation
  public init(didReceive: AsyncStream<NotificationServiceEvent>.Continuation) {
    self.didReceive = didReceive
  }

  public func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    didReceive.yield(.didReceiveResponse(identifier: response.notification.request.identifier))
  }
}

private extension NotificationsServiceRequest {
  var trigger: UNNotificationTrigger? {
    switch self {
    case let self as NotificationServiceCalendarRequest:
      return UNCalendarNotificationTrigger(dateMatching: self.dateComponents, repeats: self.repeats)
    default:
      return nil
    }
  }
}
