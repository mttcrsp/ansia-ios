import DesignSystem
import UIKit

final class AppearanceManager {
  static let shared = AppearanceManager()

  private init() {}

  func performConfiguration() {
    for configure in [configureNavigationBar, configureTabBar] {
      configure()
    }
  }

  private func configureNavigationBar() {
    let appearance = UINavigationBar.appearance()
    appearance.tintColor = DesignSystemAsset.label.color
    appearance.standardAppearance = .default
  }

  private func configureTabBar() {
    let titleAttributes: [NSAttributedString.Key: Any] = [
      .font: FontFamily.NYTFranklin.medium.font(size: 12),
      .foregroundColor: DesignSystemAsset.label.color,
    ]

    let itemAppearance = UITabBarItem.appearance()
    itemAppearance.setTitleTextAttributes(titleAttributes, for: .normal)

    let appearance = UITabBar.appearance()
    appearance.tintColor = DesignSystemAsset.label.color
  }
}
