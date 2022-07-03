import ComposableArchitecture
import Core

struct NetworkClient {
  var getFeeds: () async throws -> [Feed]
  var getItems: (String) async throws -> [Article]
  var getVideos: () async throws -> [Video]
}

extension NetworkClient: DependencyKey {
  public static let liveValue: NetworkClient = {
    let service = NetworkServiceLive.shared
    return NetworkClient(
      getFeeds: { try await service.perform(FeedsRequest()).feeds },
      getItems: { query in try await service.perform(ArticlesByQueryRequest(query: query)).articles },
      getVideos: { try await service.perform(VideosRequest()).videos }
    )
  }()

  #if DEBUG
  public static let testValue = NetworkClient(
    getFeeds: { [] },
    getItems: { _ in [] },
    getVideos: { [] }
  )
  #endif
}

extension DependencyValues {
  var networkClient: NetworkClient {
    get { self[NetworkClient.self] }
    set { self[NetworkClient.self] = newValue }
  }
}

extension NetworkServiceLive {
  static let shared: NetworkService = NetworkServiceLive(
    urlSession: .shared,
    middlewares: [NetworkLoggingMiddleware()]
  )
}
