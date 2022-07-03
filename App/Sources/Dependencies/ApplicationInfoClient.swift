import ComposableArchitecture
import Foundation

struct ApplicationInfoClient {
  var getVersion: () -> String?
  var getBuild: () -> String?
}

extension ApplicationInfoClient {
  init(bundle: Bundle) {
    self.init {
      bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    } getBuild: {
      bundle.infoDictionary?["CFBundleVersion"] as? String
    }
  }
}

extension ApplicationInfoClient: DependencyKey {
  public static let liveValue = ApplicationInfoClient(bundle: .main)

  #if DEBUG
  public static let testValue: ApplicationInfoClient = .init(
    getVersion: { nil },
    getBuild: { nil }
  )
  #endif
}

extension DependencyValues {
  var applicationInfoClient: ApplicationInfoClient {
    get { self[ApplicationInfoClient.self] }
    set { self[ApplicationInfoClient.self] = newValue }
  }
}
