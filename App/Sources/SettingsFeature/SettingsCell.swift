import DesignSystem
import UIKit

final class SettingsCell: UITableViewCell {
  static let reuseIdentifier = String(describing: SettingsCell.self)

  override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectedBackgroundView = UIView()
    tintColor = DesignSystemAsset.label.color
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    setFocused(highlighted, animated: animated)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    setFocused(selected, animated: animated)
  }

  private func setFocused(_ focused: Bool, animated _: Bool) {
    alpha = focused ? 0.5 : 1
  }
}
