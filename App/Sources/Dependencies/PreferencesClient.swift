import ComposableArchitecture
import Core

extension PreferencesClient: DependencyKey {
  public static let liveValue = PreferencesClient(
    userDefaults: .standard
  )

  #if DEBUG
  public static let testValue = PreferencesClient(
    areNotificationsDisabled: { false },
    setNotificationsDisabled: { _ in }
  )
  #endif
}

extension DependencyValues {
  var preferencesClient: PreferencesClient {
    get { self[PreferencesClient.self] }
    set { self[PreferencesClient.self] = newValue }
  }
}
