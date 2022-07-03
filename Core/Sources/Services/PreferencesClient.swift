import Foundation

public struct PreferencesClient {
  public var areNotificationsDisabled: () -> Bool
  public var setNotificationsDisabled: (Bool) -> Void
  public init(areNotificationsDisabled: @escaping () -> Bool, setNotificationsDisabled: @escaping (Bool) -> Void) {
    self.areNotificationsDisabled = areNotificationsDisabled
    self.setNotificationsDisabled = setNotificationsDisabled
  }
}

public extension PreferencesClient {
  init(userDefaults: UserDefaults) {
    let key = "com.mttcrsp.ansia.preferences.didDisableNotificationsKey"
    self.init(
      areNotificationsDisabled: { userDefaults.bool(forKey: key) },
      setNotificationsDisabled: { userDefaults.set($0, forKey: key) }
    )
  }
}
