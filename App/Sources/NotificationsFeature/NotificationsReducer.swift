import ComposableArchitecture
import Core

enum NotificationsStatus: Equatable {
  case disabled
  case enabled(NotificationsConfiguration)
}

struct NotificationsConfiguration: Equatable {
  var isVideoDayEnabled = false
  var isVideoNightEnabled = false
}

struct NotificationsReducer: ReducerProtocol {
  struct State: Equatable {
    var notificationsStatus = NotificationsStatus.disabled
    var shouldReload = false
  }

  enum Action: Equatable {
    case didLoad
    case didUnload
    case notificationsStatusChanged(NotificationsStatus)
    case allNotificationsToggled(Bool)
    case videoDayToggled(Bool)
    case videoNightToggled(Bool)
    case applicationStateChanged(ApplicationStateChange)
    case shouldReloadChanged(Bool)
  }

  @Dependency(\.applicationOpenClient) var applicationOpenClient
  @Dependency(\.applicationStateClient) var applicationStateClient
  @Dependency(\.notificationsClient) var notificationsClient
  @Dependency(\.preferencesClient) var preferencesClient

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    struct CancelLoading {}

    switch action {
    case .didLoad:
      return .merge(
        reloadStatus(),
        .run { send in
          for await change in applicationStateClient.observe() {
            await send(.applicationStateChanged(change))
          }
        }
        .cancellable(id: CancelLoading.self)
      )
    case .didUnload:
      return .cancel(id: CancelLoading.self)

    case let .applicationStateChanged(change):
      guard change.to == .foreground else {
        return .none
      }
      return .concatenate(
        .run { send in await send(.shouldReloadChanged(false)) },
        reloadStatus(),
        .run { send in await send(.shouldReloadChanged(true)) }
      )

    case let .shouldReloadChanged(shouldReload):
      state.shouldReload = shouldReload
      return .none

    case let .notificationsStatusChanged(status):
      state.notificationsStatus = status
      return .none

    case let .allNotificationsToggled(enabled):
      return .concatenate(
        .fireAndForget {
          preferencesClient.setNotificationsDisabled(!enabled)
          guard enabled else {
            return notificationsClient.removeAllRequests()
          }

          if await !notificationsClient.isAuthorized() {
            if await notificationsClient.canRequestAuthorization() {
              _ = try await notificationsClient.requestAuthorization()
            } else {
              applicationOpenClient.openNotificationSettings()
            }
          }
        },
        reloadStatus()
      )

    case let .videoDayToggled(enabled):
      return .concatenate(
        toggleNotificationRequest(VideoNotificationRequest.day, enabled: enabled),
        reloadStatus()
      )
    case let .videoNightToggled(enabled):
      return .concatenate(
        toggleNotificationRequest(VideoNotificationRequest.night, enabled: enabled),
        reloadStatus()
      )
    }
  }

  private func reloadStatus() -> EffectTask<Action> {
    .run { send in
      if preferencesClient.areNotificationsDisabled() {
        await send(.notificationsStatusChanged(.disabled))
      } else {
        let status = await notificationsClient.status()
        await send(.notificationsStatusChanged(status))
      }
    }
  }

  private func toggleNotificationRequest(_ request: VideoNotificationRequest, enabled: Bool) -> EffectTask<Action> {
    .fireAndForget {
      if enabled {
        try await notificationsClient.addRequest(request)
      } else {
        notificationsClient.removeRequest(request)
      }
    }
  }
}

private extension NotificationsClient {
  func status() async -> NotificationsStatus {
    guard await isAuthorized() else {
      return .disabled
    }

    async let isVideoDayEnabled = hasRequest(VideoNotificationRequest.day)
    async let isVideoNightEnabled = hasRequest(VideoNotificationRequest.night)
    return .enabled(
      .init(
        isVideoDayEnabled: await isVideoDayEnabled,
        isVideoNightEnabled: await isVideoNightEnabled
      )
    )
  }
}
