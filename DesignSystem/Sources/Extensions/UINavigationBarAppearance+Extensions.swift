import UIKit

public extension UINavigationBarAppearance {
  static let `default`: UINavigationBarAppearance = {
    let appearance = UINavigationBarAppearance()
    appearance.backButtonAppearance = .default
    appearance.titleTextAttributes = defaultTitleTextAttributes
    return appearance
  }()

  static let prominent: UINavigationBarAppearance = {
    let appearance = UINavigationBarAppearance()
    appearance.backButtonAppearance = .default
    appearance.titleTextAttributes = prominentTitleTextAttributes
    return appearance
  }()

  static let opaque: UINavigationBarAppearance = {
    let appearance = UINavigationBarAppearance.default
    appearance.configureWithOpaqueBackground()
    appearance.backButtonAppearance = .default
    appearance.backgroundColor = DesignSystemAsset.background.color
    appearance.titleTextAttributes = defaultTitleTextAttributes
    return appearance
  }()

  private static let defaultTitleTextAttributes: [NSAttributedString.Key: Any] = [
    .font: FontFamily.NYTFranklin.bold.font(size: 16),
    .foregroundColor: DesignSystemAsset.label.color,
    .kern: 0.2,
  ]

  private static let prominentTitleTextAttributes: [NSAttributedString.Key: Any] = [
    .font: FontFamily.NYTCheltenham.bold.font(size: 22),
    .foregroundColor: DesignSystemAsset.label.color,
    .kern: 0.4,
  ]
}
