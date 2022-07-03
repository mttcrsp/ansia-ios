import ComposableArchitecture
import Core

extension FavoritesClient: DependencyKey {
  public static let liveValue = FavoritesClient(
    userDefaults: .standard
  )

  #if DEBUG
  public static let testValue: FavoritesClient = .init(
    favoriteRegion: { nil },
    favoriteSections: { [] },
    setFavoriteRegion: { _ in },
    setFavoriteSections: { _ in },
    observeFavoriteRegion: { .init { $0.finish() } },
    observeFavoriteSections: { .init { $0.finish() } }
  )
  #endif
}

extension DependencyValues {
  var favoritesClient: FavoritesClient {
    get { self[FavoritesClient.self] }
    set { self[FavoritesClient.self] = newValue }
  }
}
