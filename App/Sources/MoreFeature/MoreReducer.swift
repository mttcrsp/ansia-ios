import ComposableArchitecture
import Core
import Foundation

struct MoreReducer: ReducerProtocol {
  struct State: Equatable {
    var article: ArticleReducer.State?
    var bookmarks: [Bookmark] = []
    var feeds: [Feed] = []
    var recents: [Recent] = []
    var resultsArticles: [Article]?
    var sectionArticles: [Article] = []
    var query = ""
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case bookmarksChanged([Bookmark])
    case feedsChanged([Feed])
    case article(ArticleReducer.Action)
    case articleSelected(Article)
    case recentsChanged([Recent])
    case resultsArticlesChanged([Article])
    case sectionArticlesChanged([Article])
    case sectionSelected(Feed)
    case sectionDeselected
    case settingsTapped
    case queryChanged(String)
  }

  @Dependency(\.continuousClock) var continuousClock
  @Dependency(\.feedsClient) var feedsClient
  @Dependency(\.networkClient) var networkClient
  @Dependency(\.persistenceClient) var persistenceClient

  var body: some ReducerProtocol<State, Action> {
    Reduce(core)
      .ifLet(\.article, action: /Action.article) {
        ArticleReducer()
      }
  }

  private func core(_ state: inout State, action: Action) -> EffectTask<Action> {
    struct CancelSearch {}
    struct CancelObservations {}
    struct CancelSectionArticlesObservation {}

    switch action {
    case .didLoad:
      return .merge(
        .run { send in
          for try await bookmarks in persistenceClient.observeBookmarks(100, 0) {
            await send(.bookmarksChanged(bookmarks))
          }
        },
        .run { send in
          for try await recents in persistenceClient.observeRecents(100) {
            await send(.recentsChanged(recents))
          }
        },
        .run { send in
          for try await feeds in persistenceClient.observeFeedsByCollection(.main) {
            await send(.feedsChanged(feeds))
          }
        }
      )
      .cancellable(id: CancelObservations.self)
    case .didUnload:
      return .cancel(ids: [
        CancelObservations.self,
        CancelSectionArticlesObservation.self,
      ])
    case let .bookmarksChanged(bookmarks):
      state.bookmarks = bookmarks
      return .none
    case let .feedsChanged(sections):
      state.feeds = sections
      return .none
    case let .recentsChanged(recents):
      state.recents = recents
      return .none

    case let .sectionSelected(feed):
      return .merge(
        .fireAndForget {
          try await feedsClient.loadArticles([feed.slug])
        },
        .run { send in
          for try await articles in persistenceClient.observeArticles(feed.slug, 30) {
            await send(.sectionArticlesChanged(articles))
          }
        }
      )
      .cancellable(id: CancelSectionArticlesObservation.self)
    case let .sectionArticlesChanged(articles):
      state.sectionArticles = articles
      return .none
    case .sectionDeselected:
      state.sectionArticles = []
      return .cancel(id: CancelSectionArticlesObservation.self)

    case let .queryChanged(rawQuery):
      let query = rawQuery.trimmingCharacters(in: .whitespaces)
      guard query != state.query, query.count >= 3 else {
        return .cancel(id: CancelSearch.self)
      }

      state.resultsArticles = nil
      state.query = query
      return .run { send in
        try await continuousClock.sleep(for: .seconds(0.5))
        let articles = try await networkClient.getItems(query)
        await send(.resultsArticlesChanged(articles))
      }
      .cancellable(id: CancelSearch.self, cancelInFlight: true)
    case let .resultsArticlesChanged(articles):
      state.resultsArticles = articles
      return .none

    case .settingsTapped:
      return .none

    case let .articleSelected(article):
      state.article = .init(article: article)
      return .none
    case .article(.didUnload):
      state.article = nil
      return .none
    case .article:
      return .none
    }
  }
}
