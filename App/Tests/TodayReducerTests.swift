@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class TodayReducerTests: XCTestCase {
  func testDidLoad() async throws {
    let feed1 = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "Sport", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.favoritesClient.favoriteRegion = { feed1.slug }
    store.dependencies.favoritesClient.favoriteSections = { [feed2.slug] }
    store.dependencies.onboardingClient.didCompleteOnboarding = { false }
    store.dependencies.onboardingClient.didWatchVideo = { true }
    store.dependencies.onboardingClient.didCompleteVideoOnboarding = { false }

    let observeApplicationState = AsyncStream<ApplicationStateChange>.streamWithContinuation()
    let observeFavoriteRegion = AsyncStream<Feed.Slug?>.streamWithContinuation()
    let observeFavoriteSections = AsyncStream<[Feed.Slug]>.streamWithContinuation()
    store.dependencies.applicationStateClient.observe = { observeApplicationState.stream }
    store.dependencies.favoritesClient.observeFavoriteRegion = { observeFavoriteRegion.stream }
    store.dependencies.favoritesClient.observeFavoriteSections = { observeFavoriteSections.stream }

    struct ObserveArticlesArgs: Hashable {
      let slug: Feed.Slug, limit: Int
    }

    let observeArticles = AsyncThrowingStream<[Article], Error>.streamWithContinuation()
    var observeArticlesArgs: [ObserveArticlesArgs] = []
    store.dependencies.persistenceClient.observeArticles = { slug, limit in
      observeArticlesArgs.append(.init(slug: slug, limit: limit))
      if slug == .home {
        return observeArticles.stream
      } else {
        return AsyncThrowingStream<[Article], Error> { _ in }
      }
    }

    var loadArticlesArgs: [[Feed.Slug]] = []
    store.dependencies.feedsClient.loadArticles = { args in
      loadArticlesArgs.append(args)
    }

    var getVideosCallCount = 0
    store.dependencies.networkClient.getVideos = {
      getVideosCallCount += 1
      return []
    }

    let task = await store.send(.didLoad) { state in
      state.canShowVideoOnboarding = true
      state.canShowRegionOnboarding = true
      state.favoriteSections = [feed2.slug]
      state.favoriteRegion = feed1.slug
    }

    let groups = TodayGroups(
      home: .init(articles: []),
      region: .init(articles: []),
      sections: [.init(articles: [])]
    )

    await store.receive(.groupsLoaded(groups)) { state in
      state.groups = groups
    }
    await store.receive(.groupsInitialLoadingCompleted) { state in
      state.areAnimationsEnabled = true
    }

    await store.receive(.favoriteRegionChanged(feed1.slug))
    await store.receive(.favoriteSectionsChanged([feed2.slug]))
    await store.receive(.isUpdatingChanged(true)) { state in
      state.isUpdating = true
    }
    await store.receive(.videoChanged(nil))
    await store.receive(.isUpdatingChanged(false)) { state in
      state.isUpdating = false
    }

    let change = ApplicationStateChange(from: .background, to: .foreground, duration: 300)
    observeApplicationState.continuation.yield(change)
    await store.receive(.applicationStateChanged(change))

    observeFavoriteRegion.continuation.yield(feed1.slug)
    await store.receive(.favoriteRegionChanged(feed1.slug))

    observeFavoriteSections.continuation.yield([feed2.slug])
    await store.receive(.favoriteSectionsChanged([feed2.slug]))

    observeArticles.continuation.yield([])
    await store.receive(.homeGroupLoaded(.init(articles: [])))

    await store.send(.didUnload).finish()
    await task.finish()

    XCTAssertEqual(getVideosCallCount, 1)
    XCTAssertEqual(Set(loadArticlesArgs), [[.main], ["1"], ["2"]])
    XCTAssertEqual(Set(observeArticlesArgs), [
      .init(slug: .main, limit: 4),
      .init(slug: "1", limit: 6),
      .init(slug: "2", limit: 4),
    ])
  }

  func testFullUpdates() async {
    let feed1 = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "Sport", collection: "2", emoji: "2", weight: 2)
    let feed3 = Feed(slug: "3", title: "Cultura", collection: "3", emoji: "3", weight: 3)

    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.favoritesClient.favoriteRegion = { feed1.slug }
    store.dependencies.favoritesClient.favoriteSections = { [feed2.slug, feed3.slug] }

    var loadArticlesArgs: [[Feed.Slug]] = []
    store.dependencies.feedsClient.loadArticles = { args in
      loadArticlesArgs.append(args)
    }

    var getVideosCallCount = 0
    store.dependencies.networkClient.getVideos = {
      getVideosCallCount += 1
      return []
    }

    await store.send(.refreshTriggered)
    await store.receive(.isUpdatingChanged(true)) { $0.isUpdating = true }
    await store.receive(.videoChanged(nil))
    await store.receive(.isUpdatingChanged(false)) { $0.isUpdating = false }

    XCTAssertEqual(getVideosCallCount, 1)
    XCTAssertEqual(loadArticlesArgs.count, 1)
    XCTAssertEqual(Set(loadArticlesArgs.last ?? []), [.main, "2", "3", "1"])

    let change = ApplicationStateChange(from: .background, to: .foreground, duration: 301)
    await store.send(.applicationStateChanged(change))
    await store.receive(.isUpdatingChanged(true)) { $0.isUpdating = true }
    await store.receive(.videoChanged(nil))
    await store.receive(.isUpdatingChanged(false)) { $0.isUpdating = false }

    XCTAssertEqual(getVideosCallCount, 2)
    XCTAssertEqual(loadArticlesArgs.count, 2)
    XCTAssertEqual(Set(loadArticlesArgs.last ?? []), [.main, "2", "3", "1"])
  }

  func testFavoriteRegionChanged() async {
    let feed = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.favoritesClient.favoriteRegion = { nil }

    var loadArticlesArgs: [[Feed.Slug]] = []
    store.dependencies.feedsClient.loadArticles = { args in
      loadArticlesArgs.append(args)
    }

    struct ObserveArticlesArgs: Hashable {
      let slug: Feed.Slug, limit: Int
    }

    let observeArticles = AsyncThrowingStream<[Article], Error>.streamWithContinuation()
    var observeArticlesArgs: [ObserveArticlesArgs] = []
    store.dependencies.persistenceClient.observeArticles = { slug, limit in
      observeArticlesArgs.append(.init(slug: slug, limit: limit))
      return observeArticles.stream
    }

    let task = await store.send(.favoriteRegionChanged(feed.slug)) { state in
      state.favoriteRegion = feed.slug
    }

    let groups = TodayGroups(home: .init(articles: []))
    await store.receive(.groupsLoaded(groups)) { state in
      state.groups = groups
    }

    observeArticles.continuation.yield([article])
    await store.receive(.regionGroupLoaded(nil))

    await store.send(.didUnload)
    await task.finish()

    XCTAssertEqual(loadArticlesArgs, [["1"]])
    XCTAssertEqual(observeArticlesArgs, [.init(slug: "1", limit: 6)])
  }

  func testFavoriteSectionsChanged() async {
    let feed = Feed(slug: "1", title: "Tecnologia", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.favoritesClient.favoriteRegion = { nil }

    var loadArticlesArgs: [[Feed.Slug]] = []
    store.dependencies.feedsClient.loadArticles = { args in
      loadArticlesArgs.append(args)
    }

    struct ObserveArticlesArgs: Hashable {
      let slug: Feed.Slug, limit: Int
    }

    let observeArticles = AsyncThrowingStream<[Article], Error>.streamWithContinuation()
    var observeArticlesArgs: [ObserveArticlesArgs] = []
    store.dependencies.persistenceClient.observeArticles = { slug, limit in
      observeArticlesArgs.append(.init(slug: slug, limit: limit))
      return observeArticles.stream
    }

    let task = await store.send(.favoriteSectionsChanged([feed.slug])) { state in
      state.favoriteSections = [feed.slug]
    }

    let groups = TodayGroups(home: .init(articles: []))
    await store.receive(.groupsLoaded(groups)) { state in
      state.groups = groups
    }

    observeArticles.continuation.yield([article])
    await store.receive(.sectionsGroupLoaded([]))

    await store.send(.didUnload)
    await task.finish()

    XCTAssertEqual(loadArticlesArgs, [["1"]])
    XCTAssertEqual(observeArticlesArgs, [.init(slug: "1", limit: 4)])
  }

  func testVideoDismissed() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.onboardingClient.didWatchVideo = { true }

    var didWatchVideo: Bool?
    store.dependencies.onboardingClient.setDidWatchVideo = {
      didWatchVideo = true
    }

    await store.send(.videoDismissed) { state in
      state.canShowVideoOnboarding = true
    }.finish()
    XCTAssertEqual(didWatchVideo, true)
  }

  func testVideoDismissedOnboardingCompleted() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.onboardingClient.didWatchVideo = { true }
    store.dependencies.onboardingClient.didCompleteVideoOnboarding = { true }

    var didWatchVideo = false
    store.dependencies.onboardingClient.setDidWatchVideo = {
      didWatchVideo = true
    }

    await store.send(.videoDismissed).finish()
    XCTAssertEqual(didWatchVideo, true)
  }

  func testVideoOnboardingCompleted() async {
    let store = TestStore(initialState: .init(canShowVideoOnboarding: true), reducer: TodayReducer())

    var didCompleteVideoOnboarding = false
    store.dependencies.onboardingClient.setDidCompleteVideoOnboarding = {
      didCompleteVideoOnboarding = true
    }

    await store.send(.videoOnboardingCompleted) { state in
      state.canShowVideoOnboarding = false
    }.finish()
    XCTAssertEqual(didCompleteVideoOnboarding, true)
  }

  func testEnableVideoNotificationsTapped() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.notificationsClient.canRequestAuthorization = { true }
    store.dependencies.notificationsClient.requestAuthorization = { true }

    var requests: [NotificationsServiceRequest] = []
    store.dependencies.notificationsClient.addRequest = { request in
      requests.append(request)
    }

    await store.send(.enableVideoNotificationsTapped).finish()
    await store.receive(.videoOnboardingCompleted)
    XCTAssertEqual(requests as? [VideoNotificationRequest], [.day, .night])
  }

  func testEnableVideoNotificationsTappedCantAuthorize() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.notificationsClient.canRequestAuthorization = { false }

    var requests: [NotificationsServiceRequest] = []
    store.dependencies.notificationsClient.addRequest = { request in
      requests.append(request)
    }

    await store.send(.enableVideoNotificationsTapped).finish()
    await store.receive(.videoOnboardingCompleted)
    XCTAssertEqual(requests.count, 0)
  }

  func testEnableVideoNotificationsTappedNotAuthorized() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    store.dependencies.notificationsClient.canRequestAuthorization = { true }
    store.dependencies.notificationsClient.requestAuthorization = { false }

    var requests: [NotificationsServiceRequest] = []
    store.dependencies.notificationsClient.addRequest = { request in
      requests.append(request)
    }

    await store.send(.enableVideoNotificationsTapped).finish()
    await store.receive(.videoOnboardingCompleted)
    XCTAssertEqual(requests.count, 0)
  }

  func testIgnoreRegionOnboardingTapped() async {
    let store = TestStore(initialState: .init(canShowRegionOnboarding: true), reducer: TodayReducer())

    var didCompleteRegionOnboarding = false
    store.dependencies.onboardingClient.setDidCompleteRegionOnboarding = {
      didCompleteRegionOnboarding = true
    }

    await store.send(.ignoreRegionOnboardingTapped) { state in
      state.canShowRegionOnboarding = false
    }.finish()
    XCTAssertEqual(didCompleteRegionOnboarding, true)
  }

  func testStartRegionOnboardingTapped() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(), reducer: TodayReducer())

    var collection: Feed.Collection?
    store.dependencies.persistenceClient.getFeedsByCollection = { value in
      collection = value
      return [feed]
    }

    await store.send(.startRegionOnboardingTapped).finish()
    await store.receive(.regionOnboardingFeedsChanged([feed])) { state in
      state.regions = [feed]
    }
    XCTAssertEqual(collection, .local)
  }

  func testRegionOnboardingFeedSelected() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(regions: [feed]), reducer: TodayReducer())
    store.exhaustivity = .off

    var slug: Feed.Slug?
    store.dependencies.favoritesClient.setFavoriteRegion = { value in
      slug = value
    }

    var didCompleteRegionOnboarding = false
    store.dependencies.onboardingClient.setDidCompleteRegionOnboarding = {
      didCompleteRegionOnboarding = true
    }

    await store.send(.regionOnboardingFeedSelected(feed)) { state in
      state.regions = nil
    }.finish()

    XCTAssertEqual(slug, feed.slug)
    XCTAssertEqual(didCompleteRegionOnboarding, true)
  }

  func testCloseRegionOnboardingTapped() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(regions: [feed]), reducer: TodayReducer())
    await store.send(.closeRegionOnboardingTapped) { state in
      state.regions = nil
    }.finish()
  }

  func testArticleSelected() async {
    let store = TestStore(initialState: .init(), reducer: TodayReducer())
    await store.send(.articleSelected(article)) { state in
      state.article = .init(article: article)
    }.finish()
  }

  func testArticleDidUnload() async {
    let store = TestStore(initialState: .init(article: .init(article: article)), reducer: TodayReducer())
    await store.send(.article(.didUnload)) { state in
      state.article = nil
    }.finish()
  }
}

private let video: Video = {
  let responseData = try! Data(contentsOf: Files.videosJson.url)
  let response = try! JSONDecoder.default.decode(VideosRequest.Response.self, from: responseData)
  let video = try! XCTUnwrap(response.videos.first)
  return video
}()

private let article: Article = {
  let articleData = try! Data(contentsOf: Files.articleJson.url)
  let article = try! JSONDecoder.default.decode(Article.self, from: articleData)
  return article
}()
