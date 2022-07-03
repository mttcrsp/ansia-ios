import Combine
import Foundation

public struct FavoritesClient {
  public var favoriteRegion: () -> Feed.Slug?
  public var favoriteSections: () -> [Feed.Slug]
  public var setFavoriteRegion: (Feed.Slug?) -> Void
  public var setFavoriteSections: ([Feed.Slug]) -> Void
  public var observeFavoriteRegion: () -> AsyncStream<Feed.Slug?>
  public var observeFavoriteSections: () -> AsyncStream<[Feed.Slug]>

  public init(favoriteRegion: @escaping () -> Feed.Slug?, favoriteSections: @escaping () -> [Feed.Slug], setFavoriteRegion: @escaping (Feed.Slug?) -> Void, setFavoriteSections: @escaping ([Feed.Slug]) -> Void, observeFavoriteRegion: @escaping () -> AsyncStream<Feed.Slug?>, observeFavoriteSections: @escaping () -> AsyncStream<[Feed.Slug]>) {
    self.favoriteRegion = favoriteRegion
    self.favoriteSections = favoriteSections
    self.setFavoriteRegion = setFavoriteRegion
    self.setFavoriteSections = setFavoriteSections
    self.observeFavoriteRegion = observeFavoriteRegion
    self.observeFavoriteSections = observeFavoriteSections
  }
}

public extension FavoritesClient {
  private static let center = NotificationCenter()

  init(userDefaults: UserDefaults) {
    let favoriteRegionKey = "com.mttcrsp.ansia.favoriteRegion"
    var favoriteRegion: Feed.Slug? {
      get { userDefaults.string(forKey: favoriteRegionKey).map(Feed.Slug.init(rawValue:)) }
      set {
        defer { Self.center.post(name: .didChangeFavoriteRegion, object: nil, userInfo: [favoriteRegionKey: newValue as Any]) }
        return userDefaults.set(newValue?.rawValue, forKey: favoriteRegionKey)
      }
    }

    let favoriteSectionsKey = "com.mttcrsp.ansia.favoriteSections"
    var favoriteSections: [Feed.Slug] {
      get { (userDefaults.object(forKey: favoriteSectionsKey) as? [String] ?? []).map(Feed.Slug.init(rawValue:)) }
      set {
        defer { Self.center.post(name: .didChangeFavoriteSections, object: nil, userInfo: [favoriteSectionsKey: newValue]) }
        return userDefaults.set(newValue.map(\.rawValue), forKey: favoriteSectionsKey)
      }
    }

    self.favoriteRegion = { favoriteRegion }
    self.favoriteSections = { favoriteSections }
    setFavoriteRegion = { favoriteRegion = $0 }
    setFavoriteSections = { favoriteSections = $0 }
    observeFavoriteRegion = {
      AsyncStream { continuation in
        let observer = Self.center.addObserver(forName: .didChangeFavoriteRegion, object: nil, queue: nil) { _ in
          continuation.yield(favoriteRegion)
        }
        continuation.onTermination = { _ in
          Self.center.removeObserver(observer)
        }
      }
    }
    observeFavoriteSections = {
      AsyncStream { continuation in
        let observer = Self.center.addObserver(forName: .didChangeFavoriteSections, object: nil, queue: nil) { _ in
          continuation.yield(favoriteSections)
        }
        continuation.onTermination = { _ in
          Self.center.removeObserver(observer)
        }
      }
    }
  }
}

private extension Notification.Name {
  static let didChangeFavoriteRegion = Self("com.mttcrsp.ansia.favoriteRegion")
  static let didChangeFavoriteSections = Self("com.mttcrsp.ansia.favoriteSections")
}
