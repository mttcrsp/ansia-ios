import ComposableArchitecture
import Core
import DesignSystem
import UIKit

final class ApplicationDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    AppearanceManager.shared.performConfiguration()

    let rootStore = Store(initialState: RootReducer.State()) {
      RootReducer()
    }
    let rootViewController = RootViewController(store: rootStore)

    window = UIWindow()
    window?.rootViewController = rootViewController
    window?.makeKeyAndVisible()
    return true
  }
}
