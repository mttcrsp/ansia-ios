import ComposableArchitecture
import Core

extension FeedsClient: DependencyKey {
  public static let liveValue = FeedsClient(
    networkService: NetworkServiceLive.shared,
    persistenceService: PersistenceServiceLive.shared
  )

  #if DEBUG
  public static let testValue = FeedsClient(
    loadArticles: { _ in }
  )
  #endif
}

extension DependencyValues {
  var feedsClient: FeedsClient {
    get { self[FeedsClient.self] }
    set { self[FeedsClient.self] = newValue }
  }
}
