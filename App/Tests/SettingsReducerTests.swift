@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class SettingsReducerTests: XCTestCase {
  func testLoading() async throws {
    let build = "1", version = "1.0"
    let databaseURL = try XCTUnwrap(URL(filePath: "/test"))
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: SettingsReducer())
    store.dependencies.applicationInfoClient.getBuild = { build }
    store.dependencies.applicationInfoClient.getVersion = { version }
    store.dependencies.persistenceClient.getPath = { databaseURL.path }
    store.dependencies.favoritesClient.favoriteRegion = { feed1.slug }
    store.dependencies.favoritesClient.favoriteSections = { [feed2.slug] }

    var getFeedSlug: Feed.Slug?
    store.dependencies.persistenceClient.getFeed = { value in
      getFeedSlug = value
      return feed1
    }

    var getFeedsSlugs: [Feed.Slug]?
    store.dependencies.persistenceClient.getFeeds = { value in
      getFeedsSlugs = value
      return [feed2]
    }

    let task = await store.send(.didLoad) { state in
      state.applicationBuild = build
      state.applicationVersion = version
      state.databaseURL = databaseURL
    }

    await store.receive(.favoriteSectionsChanged([feed2])) { state in
      state.favoriteSections = [feed2]
    }

    await store.receive(.favoriteRegionChanged(feed1)) { state in
      state.favoriteRegion = feed1
    }

    await store.send(.didUnload).finish()
    await task.finish()

    XCTAssertEqual(getFeedSlug, feed1.slug)
    XCTAssertEqual(getFeedsSlugs, [feed2.slug])
  }

  func testLoadingFeedsObservers() async throws {
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: SettingsReducer())

    let localFeed = AsyncThrowingStream<[Feed], Error>.streamWithContinuation()
    let mainFeed = AsyncThrowingStream<[Feed], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeFeedsByCollection = { collection in
      switch collection {
      case .local:
        return localFeed.stream
      case .main:
        return mainFeed.stream
      default:
        XCTFail("unexpected collection '\(collection.rawValue)'")
        return mainFeed.stream
      }
    }

    let task = await store.send(.didLoad)
    await store.receive(.favoriteSectionsChanged([]))

    localFeed.continuation.yield([feed1])
    await store.receive(.regionsChanged([feed1])) { state in
      state.regions = [feed1]
    }

    mainFeed.continuation.yield([feed2])
    await store.receive(.sectionsChanged([feed2])) { state in
      state.sections = [feed2]
    }

    await store.send(.didUnload).finish()
    await task.finish()
  }

  func testLoadingFavoritesObservers() async throws {
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: SettingsReducer())

    let favoriteRegion = AsyncStream<Feed.Slug?>.streamWithContinuation()
    store.dependencies.favoritesClient.observeFavoriteRegion = {
      favoriteRegion.stream
    }

    let favoriteSections = AsyncStream<[Feed.Slug]>.streamWithContinuation()
    store.dependencies.favoritesClient.observeFavoriteSections = {
      favoriteSections.stream
    }

    var getFeedSlug: Feed.Slug?
    store.dependencies.persistenceClient.getFeed = { value in
      getFeedSlug = value
      return feed1
    }

    var getFeedsSlugs: [Feed.Slug]?
    store.dependencies.persistenceClient.getFeeds = { value in
      getFeedsSlugs = value
      return [feed2]
    }

    let task = await store.send(.didLoad)

    await store.receive(.favoriteSectionsChanged([feed2])) { state in
      state.favoriteSections = [feed2]
    }

    favoriteSections.continuation.yield([feed2.slug])
    await store.receive(.favoriteSectionsChanged([feed2]))

    favoriteRegion.continuation.yield(feed1.slug)
    await store.receive(.favoriteRegionChanged(feed1)) { state in
      state.favoriteRegion = feed1
    }

    await store.send(.didUnload).finish()
    await task.finish()
    XCTAssertEqual(getFeedSlug, feed1.slug)
    XCTAssertEqual(getFeedsSlugs, [feed2.slug])
  }

  func testFavoriteRegionSelected() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(), reducer: SettingsReducer())

    var favoriteRegion: Feed.Slug?
    store.dependencies.favoritesClient.setFavoriteRegion = { value in
      favoriteRegion = value
    }

    await store.send(.favoriteRegionSelected(feed)).finish()
    XCTAssertEqual(favoriteRegion, feed.slug)
  }

  func testFavoriteSectionsSelected() async {
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: SettingsReducer())

    var favoriteSections: [Feed.Slug]?
    store.dependencies.favoritesClient.setFavoriteSections = { value in
      favoriteSections = value
    }

    await store.send(.favoriteSectionsSelected([feed1, feed2])).finish()
    XCTAssertEqual(favoriteSections, [feed1.slug, feed2.slug])
  }

  func testNotificationsSelected() async {
    let store = TestStore(initialState: .init(), reducer: SettingsReducer())
    await store.send(.notificationsSelected).finish()
  }
}
