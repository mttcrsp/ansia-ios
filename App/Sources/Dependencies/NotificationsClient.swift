import ComposableArchitecture
import Core

extension NotificationsClient: DependencyKey {
  public static let liveValue = NotificationsClient()

  #if DEBUG
  public static let testValue = NotificationsClient(
    requestAuthorization: { false },
    canRequestAuthorization: { false },
    isAuthorized: { false },
    hasRequest: { _ in false },
    addRequest: { _ in },
    removeRequest: { _ in },
    removeAllRequests: {},
    observe: { .init { $0.finish() } }
  )
  #endif
}

extension DependencyValues {
  var notificationsClient: NotificationsClient {
    get { self[NotificationsClient.self] }
    set { self[NotificationsClient.self] = newValue }
  }
}
