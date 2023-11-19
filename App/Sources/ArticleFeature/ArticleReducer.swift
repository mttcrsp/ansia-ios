import ComposableArchitecture
import Core
import Foundation

struct ArticleReducer: Reducer {
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

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    enum CancelID {
      case bookmarksObservation
    }

    switch action {
    case .didLoad:
      return .run { [state] send in
        for try await bookmark in persistenceClient.observeBookmark(state.article.articleID) {
          await send(.bookmarkStatusChanged(bookmark))
        }
      }
      .cancellable(id: CancelID.bookmarksObservation)
    case .didUnload:
      return .cancel(id: CancelID.bookmarksObservation)

    case .didAppear:
      return .run { [state] _ in
        let recent = Recent(article: state.article, createdAt: date.now)
        try await persistenceClient.upsertRecent(recent)
      }

    case let .bookmarkStatusChanged(bookmark):
      state.showsBookmark = bookmark != nil
      return .none

    case .bookmarkStatusToggled:
      return .run { [state] _ in
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
