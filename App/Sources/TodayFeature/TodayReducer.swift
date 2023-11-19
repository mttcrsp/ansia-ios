import ComposableArchitecture
import Core
import Foundation

struct TodayReducer: Reducer {
  struct State: Equatable {
    var areAnimationsEnabled = false
    var article: ArticleReducer.State?
    var canShowRegionOnboarding = false
    var canShowVideoOnboarding = false
    var favoriteRegion: Feed.Slug?
    var favoriteSections: [Feed.Slug] = []
    var groups = TodayGroups()
    var isUpdating = false
    var regions: [Feed]?
    var video: Video?
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case refreshTriggered

    case groupsInitialLoadingCompleted
    case groupsLoaded(TodayGroups)
    case homeGroupLoaded(TodayGroup)
    case regionGroupLoaded(TodayGroup?)
    case sectionsGroupLoaded([TodayGroup])

    case isUpdatingChanged(Bool)
    case applicationStateChanged(ApplicationStateChange)
    case favoriteRegionChanged(Feed.Slug?)
    case favoriteSectionsChanged([Feed.Slug])

    case videoChanged(Video?)
    case videoDismissed
    case enableVideoNotificationsTapped
    case videoOnboardingCompleted

    case ignoreRegionOnboardingTapped
    case startRegionOnboardingTapped
    case closeRegionOnboardingTapped
    case regionOnboardingFeedSelected(Feed)
    case regionOnboardingFeedsChanged([Feed])

    case article(ArticleReducer.Action)
    case articleSelected(Article)
  }

  @Dependency(\.applicationStateClient) var applicationStateClient
  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.feedsClient) var feedsClient
  @Dependency(\.networkClient) var networkClient
  @Dependency(\.notificationsClient) var notificationsClient
  @Dependency(\.onboardingClient) var onboardingClient
  @Dependency(\.persistenceClient) var persistenceClient

  var body: some ReducerOf<Self> {
    Reduce(core)
      .ifLet(\.article, action: /Action.article) {
        ArticleReducer()
      }
  }

  private func core(_ state: inout State, action: Action) -> Effect<Action> {
    enum CancelID {
      case favoriteRegionObservation
      case favoriteSectionsObservation
      case loading
    }

    switch action {
    case .didLoad:
      state.favoriteRegion = favoritesClient.favoriteRegion()
      state.favoriteSections = favoritesClient.favoriteSections()
      state.canShowRegionOnboarding = !onboardingClient.didCompleteRegionOnboarding()
      state.canShowVideoOnboarding = onboardingClient.canShowVideoOnboarding
      return .concatenate(
        reloadGroups(),
        .run { send in
          await send(.groupsInitialLoadingCompleted)
          await send(.favoriteRegionChanged(favoritesClient.favoriteRegion()))
          await send(.favoriteSectionsChanged(favoritesClient.favoriteSections()))
        },
        .merge(
          .concatenate(
            .run { send in await send(.isUpdatingChanged(true)) },
            .merge(updateFeeds([.home]), updateVideo()),
            .run { send in await send(.isUpdatingChanged(false)) }
          ),
          .run { send in
            for await slug in favoritesClient.observeFavoriteRegion() {
              await send(.favoriteRegionChanged(slug))
            }
          },
          .run { send in
            for await slugs in favoritesClient.observeFavoriteSections() {
              await send(.favoriteSectionsChanged(slugs))
            }
          },
          .run { send in
            for await change in applicationStateClient.observe() {
              await send(.applicationStateChanged(change))
            }
          },
          .run { send in
            for try await articles in persistenceClient.observeArticles(.home, 4) {
              await send(.homeGroupLoaded(.init(articles: articles)))
            }
          }
        )
      )
      .cancellable(id: CancelID.loading)
    case .didUnload:
      return .cancel(id: [
        CancelID.loading,
        CancelID.favoriteRegionObservation,
        CancelID.favoriteSectionsObservation,
      ])

    case .refreshTriggered:
      return updateAllFeedsAndVideo()
    case let .applicationStateChanged(change):
      return change.isSignificantTimeInBackground
        ? updateAllFeedsAndVideo()
        : .none
    case let .favoriteRegionChanged(slug):
      var effects: [Effect<Action>] = []
      if state.favoriteRegion != slug {
        state.favoriteRegion = slug
        effects.append(reloadGroups())
      }

      if let slug {
        effects.append(updateFeeds([slug]))
        effects.append(
          .run { send in
            for try await _ in persistenceClient.observeArticles(slug, 6) {
              let group = try await todayClient.getRegion()
              await send(.regionGroupLoaded(group))
            }
          }
        )
      }
      return .merge(effects)
        .cancellable(id: CancelID.favoriteRegionObservation, cancelInFlight: true)
    case let .favoriteSectionsChanged(slugs):
      var effects: [Effect<Action>] = []
      if state.favoriteSections != slugs {
        state.favoriteSections = slugs
        effects.append(reloadGroups())
      }

      if !slugs.isEmpty {
        effects.append(updateFeeds(slugs))
        effects.append(
          .merge(
            slugs.map { slug in
              .run { send in
                for try await _ in persistenceClient.observeArticles(slug, 4) {
                  let groups = try await todayClient.getSections()
                  await send(.sectionsGroupLoaded(groups))
                }
              }
            }
          )
        )
      }
      return .merge(effects)
        .cancellable(id: CancelID.favoriteSectionsObservation, cancelInFlight: true)

    case let .isUpdatingChanged(isLoading):
      state.isUpdating = isLoading
      return .none

    case .groupsInitialLoadingCompleted:
      state.areAnimationsEnabled = true
      return .none
    case let .groupsLoaded(content):
      state.groups = content
      return .none
    case let .homeGroupLoaded(home):
      state.groups.home = home
      return .none
    case let .regionGroupLoaded(region):
      state.groups.region = region
      return .none
    case let .sectionsGroupLoaded(sections):
      state.groups.sections = sections
      return .none

    case let .videoChanged(video):
      state.video = video
      return .none
    case .videoDismissed:
      onboardingClient.setDidWatchVideo()
      if onboardingClient.canShowVideoOnboarding {
        state.canShowVideoOnboarding = true
      }
      return .none
    case .enableVideoNotificationsTapped:
      return .run { send in
        do {
          if await notificationsClient.canRequestAuthorization() {
            if try await notificationsClient.requestAuthorization() {
              try await notificationsClient.addRequest(VideoNotificationRequest.day)
              try await notificationsClient.addRequest(VideoNotificationRequest.night)
            }
          }
        } catch {}
        await send(.videoOnboardingCompleted)
      }
    case .videoOnboardingCompleted:
      onboardingClient.setDidCompleteVideoOnboarding()
      state.canShowVideoOnboarding = false
      return .none

    case .ignoreRegionOnboardingTapped:
      onboardingClient.setDidCompleteRegionOnboarding()
      state.canShowRegionOnboarding = false
      return .none
    case .startRegionOnboardingTapped:
      return .run { send in
        let regions = try await persistenceClient.getFeedsByCollection(.local)
        await send(.regionOnboardingFeedsChanged(regions))
      }
    case let .regionOnboardingFeedsChanged(regions):
      state.regions = regions
      return .none
    case let .regionOnboardingFeedSelected(region):
      favoritesClient.setFavoriteRegion(region.slug)
      onboardingClient.setDidCompleteRegionOnboarding()
      state.regions = nil
      return .none
    case .closeRegionOnboardingTapped:
      state.regions = nil
      return .none

    case let .articleSelected(article):
      state.article = ArticleReducer.State(article: article)
      return .none
    case .article(.didUnload):
      state.article = nil
      return .none
    case .article:
      return .none
    }
  }

  private var allFeeds: [Feed.Slug] {
    var slugs: [Feed.Slug] = [.home]
      + favoritesClient.favoriteSections()
    if let slug = favoritesClient.favoriteRegion() {
      slugs.append(slug)
    }
    return slugs
  }

  private func updateAllFeedsAndVideo() -> Effect<Action> {
    .concatenate(
      .run { send in await send(.isUpdatingChanged(true)) },
      .merge(updateFeeds(allFeeds), updateVideo()),
      .run { send in await send(.isUpdatingChanged(false)) }
    )
  }

  private func updateFeeds(_ slugs: [Feed.Slug]) -> Effect<Action> {
    .run { _ in
      try await feedsClient.loadArticles(slugs)
    }
  }

  private func updateVideo() -> Effect<Action> {
    .run { send in
      let videos = try await networkClient.getVideos()
      await send(.videoChanged(videos.first))
    }
  }

  private func reloadGroups() -> Effect<Action> {
    .run { send in
      let groups = try await todayClient.getGroups()
      await send(.groupsLoaded(groups))
    }
  }

  private var todayClient: TodayClient {
    .init(
      favoritesClient: favoritesClient,
      persistenceClient: persistenceClient
    )
  }
}

private extension OnboardingClient {
  var canShowVideoOnboarding: Bool {
    didWatchVideo() && !didCompleteVideoOnboarding()
  }
}

private extension ApplicationStateChange {
  var isSignificantTimeInBackground: Bool {
    from == .background && to == .foreground && duration > 60 * 5
  }
}
