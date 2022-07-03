import ComposableArchitecture
import Core
import Foundation

struct ArticleReducer: ReducerProtocol {
  struct State: Equatable, Hashable {
    let article: Article
    var showsBookmark = false
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case didAppear
    case bookmarkStatusChanged(Bookmark?)
    case bookmarkStatusToggled
  }

  @Dependency(\.date) var date
  @Dependency(\.persistenceClient) var persistenceClient

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    enum CancelLoading {}

    switch action {
    case .didLoad:
      return .run { [state] send in
        for try await bookmark in persistenceClient.observeBookmark(state.article.articleID) {
          await send(.bookmarkStatusChanged(bookmark))
        }
      }
      .cancellable(id: CancelLoading.self)
    case .didUnload:
      return .cancel(id: CancelLoading.self)

    case .didAppear:
      return .fireAndForget { [state] in
        let recent = Recent(article: state.article, createdAt: date.now)
        try await persistenceClient.upsertRecent(recent)
      }

    case let .bookmarkStatusChanged(bookmark):
      state.showsBookmark = bookmark != nil
      return .none

    case .bookmarkStatusToggled:
      return .fireAndForget { [state] in
        if state.showsBookmark {
          try await persistenceClient.deleteBookmark(state.article.articleID)
        } else {
          let bookmark = Bookmark(article: state.article, createdAt: date.now)
          try await persistenceClient.insertBookmark(bookmark)
        }
      }
    }
  }
}
