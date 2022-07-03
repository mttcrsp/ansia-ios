import ComposableArchitecture
import Core
import Foundation

extension SetupClient: DependencyKey {
  public static let liveValue = SetupClient(
    fileManager: FileManager.default,
    networkService: NetworkServiceLive.shared,
    persistenceService: PersistenceServiceLive.shared
  )

  #if DEBUG
  public static let testValue =
    SetupClient(perform: {})
  #endif
}

extension DependencyValues {
  var setupClient: SetupClient {
    get { self[SetupClient.self] }
    set { self[SetupClient.self] = newValue }
  }
}
