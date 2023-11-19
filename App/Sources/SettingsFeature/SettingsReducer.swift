import ComposableArchitecture
import Core
import Foundation

struct SettingsReducer: Reducer {
  struct State: Equatable {
    var applicationBuild: String?
    var applicationVersion: String?
    var databaseURL: URL?
    var favoriteSections: [Feed] = []
    var favoriteRegion: Feed?
    var regions: [Feed] = []
    var sections: [Feed] = []
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case regionsChanged([Feed])
    case sectionsChanged([Feed])
    case favoriteRegionSelected(Feed?)
    case favoriteSectionsSelected([Feed])
    case favoriteRegionChanged(Feed?)
    case favoriteSectionsChanged([Feed])
    case notificationsSelected
  }

  @Dependency(\.applicationInfoClient) var applicationInfoClient
  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.persistenceClient) var persistenceClient

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    enum CancelID {
      case loading
    }

    switch action {
    case .didLoad:
      state.applicationBuild = applicationInfoClient.getBuild()
      state.applicationVersion = applicationInfoClient.getVersion()
      if let path = persistenceClient.getPath() {
        state.databaseURL = URL(filePath: path)
      }

      return .merge(
        .run { send in
          let slugs = favoritesClient.favoriteSections()
          let feeds = try await persistenceClient.getFeeds(slugs)
          await send(.favoriteSectionsChanged(feeds))

          if let slug = favoritesClient.favoriteRegion() {
            let feed = try await persistenceClient.getFeed(slug)
            await send(.favoriteRegionChanged(feed))
          }
        },
        .run { send in
          for try await slugs in favoritesClient.observeFavoriteSections() {
            let feeds = try await persistenceClient.getFeeds(slugs)
            await send(.favoriteSectionsChanged(feeds))
          }
        },
        .run { send in
          for try await slug in favoritesClient.observeFavoriteRegion() {
            if let slug {
              let feed = try await persistenceClient.getFeed(slug)
              await send(.favoriteRegionChanged(feed))
            } else {
              await send(.favoriteRegionChanged(nil))
            }
          }
        },
        .run { send in
          for try await feeds in persistenceClient.observeFeedsByCollection(.local) {
            await send(.regionsChanged(feeds))
          }
        },
        .run { send in
          for try await feeds in persistenceClient.observeFeedsByCollection(.main) {
            await send(.sectionsChanged(feeds))
          }
        }
      )
      .cancellable(id: CancelID.loading)
    case .didUnload:
      return .cancel(id: CancelID.loading)

    case let .favoriteRegionSelected(region):
      favoritesClient.setFavoriteRegion(region?.slug)
      return .none
    case let .favoriteSectionsSelected(sections):
      favoritesClient.setFavoriteSections(sections.map(\.slug))
      return .none

    case let .favoriteRegionChanged(region):
      state.favoriteRegion = region
      return .none
    case let .favoriteSectionsChanged(sections):
      state.favoriteSections = sections
      return .none

    case let .regionsChanged(regions):
      state.regions = regions
      return .none
    case let .sectionsChanged(sections):
      state.sections = sections
      return .none

    case .notificationsSelected:
      return .none
    }
  }
}
