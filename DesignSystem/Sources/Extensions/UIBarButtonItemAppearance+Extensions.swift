import UIKit

public extension UIBarButtonItemAppearance {
  static let `default`: UIBarButtonItemAppearance = {
    let titleTextAttributes: [NSAttributedString.Key: Any] = [
      .font: FontFamily.NYTFranklin.medium.font(size: 16),
      .foregroundColor: DesignSystemAsset.label.color,
    ]

    let appearance = UIBarButtonItemAppearance()
    appearance.normal.titleTextAttributes = titleTextAttributes
    appearance.highlighted.titleTextAttributes = titleTextAttributes
    return appearance
  }()
}
