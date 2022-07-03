import ComposableArchitecture
import UIKit

struct ApplicationOpenClient {
  var openNotificationSettings: () -> Void
}

extension ApplicationOpenClient {
  init(application: UIApplication) {
    openNotificationSettings = {
      if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
        DispatchQueue.main.async {
          application.open(url)
        }
      }
    }
  }
}

extension ApplicationOpenClient: DependencyKey {
  static let liveValue = ApplicationOpenClient(
    application: .shared
  )

  #if DEBUG
  static let testValue = ApplicationOpenClient(
    openNotificationSettings: {}
  )
  #endif
}

extension DependencyValues {
  var applicationOpenClient: ApplicationOpenClient {
    get { self[ApplicationOpenClient.self] }
    set { self[ApplicationOpenClient.self] = newValue }
  }
}
