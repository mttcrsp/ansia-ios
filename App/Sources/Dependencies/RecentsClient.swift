import ComposableArchitecture
import Core

extension RecentsClient: DependencyKey {
  public static let liveValue = RecentsClient(
    persistenceService: PersistenceServiceLive.shared
  )

  #if DEBUG
  public static let testValue = RecentsClient(
    startMonitoring: {},
    stopMonitoring: {}
  )
  #endif
}

extension DependencyValues {
  var recentsClient: RecentsClient {
    get { self[RecentsClient.self] }
    set { self[RecentsClient.self] = newValue }
  }
}
