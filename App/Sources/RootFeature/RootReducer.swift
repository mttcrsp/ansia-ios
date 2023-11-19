import ComposableArchitecture
import Core

struct RootReducer: Reducer {
  enum Content: Equatable {
    case loading
    case failure
    case success
  }

  struct State: Equatable {
    var content: Content = .loading
    var today: TodayReducer.State?
    var more = MoreReducer.State()
    var notifications: NotificationsReducer.State?
    var onboarding: OnboardingReducer.State?
    var settings: SettingsReducer.State?
    var showsError = false
  }

  enum Action: Equatable {
    case didLoad
    case setupCompleted(Bool)
    case setupRetryTapped
    case more(MoreReducer.Action)
    case notifications(NotificationsReducer.Action)
    case onboarding(OnboardingReducer.Action)
    case settings(SettingsReducer.Action)
    case today(TodayReducer.Action)
  }

  @Dependency(\.applicationStateClient) var applicationStateClient
  @Dependency(\.onboardingClient) var onboardingClient
  @Dependency(\.recentsClient) var recentsClient
  @Dependency(\.setupClient) var setupClient

  var body: some ReducerOf<Self> {
    Reduce(core)
      .ifLet(\.today, action: /Action.today) {
        TodayReducer()
      }
      .ifLet(\.notifications, action: /Action.notifications) {
        NotificationsReducer()
      }
      .ifLet(\.onboarding, action: /Action.onboarding) {
        OnboardingReducer()
      }
      .ifLet(\.settings, action: /Action.settings) {
        SettingsReducer()
      }
    Scope(state: \.more, action: /Action.more) {
      MoreReducer()
    }
  }

  private func core(_ state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didLoad:
      recentsClient.startMonitoring()
      if !onboardingClient.didCompleteOnboarding() {
        state.onboarding = .init()
      } else {
        state.today = .init()
      }
      return performSetup()
    case let .setupCompleted(success):
      state.content = success ? .success : .failure
      return .none
    case .setupRetryTapped:
      state.content = .loading
      return performSetup()
    case .onboarding(.didComplete):
      state.today = .init()
      return .none
    case .more(.settingsTapped):
      state.settings = .init()
      return .none
    case .notifications(.didUnload):
      state.notifications = nil
      return .none
    case .settings(.didUnload):
      state.settings = nil
      return .none
    case .settings(.notificationsSelected):
      state.notifications = .init()
      return .none
    case .today, .onboarding, .notifications, .more, .settings:
      return .none
    }
  }

  private func performSetup() -> Effect<Action> {
    .run { send in
      try await setupClient.perform()
      await send(.setupCompleted(true))
    } catch: { _, send in
      await send(.setupCompleted(false))
    }
  }
}
