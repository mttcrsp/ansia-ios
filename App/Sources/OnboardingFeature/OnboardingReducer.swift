import ComposableArchitecture
import Core

struct OnboardingReducer: Reducer {
  struct State: Equatable {
    var didFail = false
    var sections: [Feed] = []
    var minimumSectionsAlert: AlertState<Action>?
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case didComplete
    case sectionsLoadingFailed
    case sectionsLoadingRetryTapped
    case sectionsChanged([Feed])
    case sectionsConfirmTapped([Feed])
    case minimumSectionsDismissTapped
  }

  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.networkClient) var networkClient
  @Dependency(\.onboardingClient) var onboardingClient
  @Dependency(\.persistenceClient) var persistenceClient

  private let minSectionsCount = 3

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    enum CancelID {
      case feedsObservation
    }

    switch action {
    case .didLoad:
      return .merge(
        updateSections(),
        .run { send in
          for try await sections in persistenceClient.observeFeedsByCollection(.main) {
            await send(.sectionsChanged(sections))
          }
        }
        .cancellable(id: CancelID.feedsObservation)
      )
    case .didUnload:
      return .cancel(id: CancelID.feedsObservation)
    case let .sectionsChanged(sections):
      state.sections = sections
      return .none
    case let .sectionsConfirmTapped(selectedSections):
      if selectedSections.count >= minSectionsCount {
        return handleValidConfirm(selectedSections)
      } else {
        return handleInvalidConfirm(&state)
      }
    case .minimumSectionsDismissTapped:
      state.minimumSectionsAlert = nil
      return .none
    case .sectionsLoadingFailed:
      state.didFail = true
      return .none
    case .sectionsLoadingRetryTapped:
      state.didFail = false
      return updateSections()
    case .didComplete:
      return .none
    }
  }

  private func updateSections() -> Effect<Action> {
    .run { _ in
      let feeds = try await networkClient.getFeeds()
      try await persistenceClient.updateFeeds(feeds)
    } catch: { _, send in
      await send(.sectionsLoadingFailed)
    }
  }

  private func handleInvalidConfirm(_ state: inout State) -> Effect<Action> {
    let title = L10n.Onboarding.atLeastXSections(minSectionsCount)
    state.minimumSectionsAlert = .init(
      title: TextState(title),
      buttons: [
        .default(
          TextState(L10n.Onboarding.continue),
          action: .send(.minimumSectionsDismissTapped)
        ),
      ]
    )
    return .none
  }

  private func handleValidConfirm(_ sections: [Feed]) -> Effect<Action> {
    favoritesClient.setFavoriteSections(sections.map(\.slug))
    onboardingClient.setDidCompleteOnboarding()
    return .run { send in
      await send(.didComplete)
    }
  }
}
