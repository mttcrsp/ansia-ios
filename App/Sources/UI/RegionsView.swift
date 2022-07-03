import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct RegionsConfiguration: Equatable {
  var feeds: [Feed] = []
  var selectedFeed: Feed?
}

final class RegionsView: UITableView {
  var onFeedSelected: (Feed) -> Void = { _ in }

  var configuration = RegionsConfiguration() {
    didSet { reloadData() }
  }

  init() {
    super.init(frame: .zero, style: .grouped)
    dataSource = self
    delegate = self
    register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func feed(at indexPath: IndexPath) -> Feed {
    configuration.feeds[indexPath.row]
  }
}

extension RegionsView: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    configuration.feeds.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as! SettingsCell
    let feed = feed(at: indexPath)

    var configuration = cell.defaultContentConfiguration()
    configuration.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    configuration.attributedText = NSAttributedString(
      string: feed.title,
      attributes: [
        .font: FontFamily.NYTFranklin.medium.font(size: 16),
        .foregroundColor: DesignSystemAsset.label.color,
        .kern: 0.5,
      ]
    )
    cell.accessoryType = feed == self.configuration.selectedFeed ? .checkmark : .none
    cell.contentConfiguration = configuration
    return cell
  }
}

extension RegionsView: UITableViewDelegate {
  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    onFeedSelected(feed(at: indexPath))
  }

  func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
    UITableViewHeaderFooterView()
  }

  func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    0
  }
}
