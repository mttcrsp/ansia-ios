import Core
import DesignSystem
import UIKit

struct SectionsConfiguration: Equatable {
  var feeds: [Feed] = []
  var selectedFeeds: Set<Feed> = []
}

final class SectionsView: UITableView {
  var configuration = SectionsConfiguration() {
    didSet { didChangeConfiguration(from: oldValue, to: configuration) }
  }

  init() {
    super.init(frame: .zero, style: .grouped)
    allowsSelection = false
    backgroundColor = .clear
    dataSource = self
    delegate = self
    register(SectionsCell.self, forCellReuseIdentifier: SectionsCell.reuseIdentifier)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func didChangeConfiguration(from oldValue: SectionsConfiguration, to newValue: SectionsConfiguration) {
    if oldValue.feeds != newValue.feeds {
      reloadData()
    }
  }
}

extension SectionsView: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    configuration.feeds.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let feed = configuration.feeds[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: SectionsCell.reuseIdentifier, for: indexPath) as! SectionsCell
    cell.configuration = .init(feed: feed, isSelected: configuration.selectedFeeds.contains(feed))
    cell.onValueChanged = { [weak self] feed, isSelected in
      if isSelected {
        self?.configuration.selectedFeeds.insert(feed)
      } else {
        self?.configuration.selectedFeeds.remove(feed)
      }
    }
    return cell
  }
}

extension SectionsView: UITableViewDelegate {
  func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
    UITableViewHeaderFooterView()
  }

  func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    0
  }
}

private final class SectionsCell: UITableViewCell {
  static let reuseIdentifier = String(describing: SectionsCell.self)

  struct Configuration {
    var feed: Feed?
    var isSelected = false
  }

  var configuration = Configuration() {
    didSet { didChangeConfiguration() }
  }

  var onValueChanged: (Feed, Bool) -> Void = { _, _ in }

  private let `switch` = UISwitch()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    `switch`.addTarget(self, action: #selector(SectionsCell.valueChanged), for: .valueChanged)
    `switch`.onTintColor = DesignSystemAsset.fill.color
    accessoryView = `switch`
    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func didChangeConfiguration() {
    if configuration.feed?.slug == .home {
      `switch`.isEnabled = false
      `switch`.isOn = true
    } else {
      `switch`.isEnabled = true
      `switch`.isOn = configuration.isSelected
    }

    var contentConfiguration = defaultContentConfiguration()
    contentConfiguration.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    contentConfiguration.attributedText = NSAttributedString(
      string: configuration.feed?.title ?? "",
      attributes: [
        .font: FontFamily.NYTFranklin.medium.font(size: 16),
        .foregroundColor: DesignSystemAsset.label.color,
        .kern: 0.5,
      ]
    )
    self.contentConfiguration = contentConfiguration
  }

  @objc private func valueChanged(_ switch: UISwitch) {
    if let feed = configuration.feed {
      onValueChanged(feed, `switch`.isOn)
    }
  }
}
