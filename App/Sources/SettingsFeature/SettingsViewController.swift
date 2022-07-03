import AsyncDisplayKit
import Combine
import ComposableArchitecture
import Core
import DesignSystem

enum SettingsItem {
  case exportDatabase
  case favoriteRegion
  case favoriteSections
  case notifications
}

struct SettingsSection: CaseIterable {
  enum Identifier {
    case today, notifications, debug
  }

  let identifier: Identifier
  let items: [SettingsItem]
  static let allCases: [SettingsSection] = [
    .init(identifier: .today, items: [.favoriteRegion, .favoriteSections]),
    .init(identifier: .notifications, items: [.notifications]),
    .init(identifier: .debug, items: [.exportDatabase]),
  ]
}

final class SettingsViewController: UITableViewController {
  private let sections = SettingsSection.allCases
  private let viewStore: ViewStoreOf<SettingsReducer>
  private var cancellables: Set<AnyCancellable> = []
  private weak var regionViewController: SettingsRegionViewController?

  init(store: StoreOf<SettingsReducer>) {
    viewStore = ViewStore(store)
    super.init(style: .grouped)
    clearsSelectionOnViewWillAppear = true
    hidesBottomBarWhenPushed = true
    navigationItem.standardAppearance = .opaque
    title = L10n.Settings.title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.backgroundColor = DesignSystemAsset.background.color
    tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
    tableView.register(SettingsFooter.self, forHeaderFooterViewReuseIdentifier: SettingsFooter.reuseIdentifier)

    viewStore.publisher
      .sink { [weak self] _ in
        self?.tableView.reloadData()
      }
      .store(in: &cancellables)

    viewStore.publisher
      .map(RegionsConfiguration.init)
      .removeDuplicates()
      .sink { [weak self] configuration in
        self?.regionViewController?.configuration = configuration
      }
      .store(in: &cancellables)

    viewStore.send(.didLoad)
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      viewStore.send(.didUnload)
    }
  }

  override func numberOfSections(in _: UITableView) -> Int {
    sections.count
  }

  override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
    UITableViewHeaderFooterView()
  }

  override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    0
  }

  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard sections[section].identifier == .debug else {
      return nil
    }

    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingsFooter.reuseIdentifier) as! SettingsFooter
    var configuration = view.defaultContentConfiguration()
    configuration.textProperties.alignment = .center
    configuration.textProperties.color = DesignSystemAsset.tertiaryLabel.color
    configuration.textProperties.font = FontFamily.NYTFranklin.medium.font(size: 14)
    configuration.text = viewStore.applicationIdentifiers
    view.contentConfiguration = configuration
    return view
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = item(at: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as! SettingsCell
    var configuration = cell.defaultContentConfiguration()
    configuration.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    configuration.attributedText = .init(
      string: text(for: item),
      attributes: attributes(withForegroundColor: DesignSystemAsset.label.color)
    )
    if let string = secondaryText(for: item) {
      configuration.secondaryAttributedText = .init(
        string: string,
        attributes: attributes(withForegroundColor: DesignSystemAsset.tertiaryLabel.color)
      )
    }

    cell.accessoryType = accessoryType(for: item)
    cell.contentConfiguration = configuration
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch item(at: indexPath) {
    case .exportDatabase:
      if let url = viewStore.databaseURL {
        showShare(with: url)
      }
    case .favoriteRegion:
      showRegion()
    case .favoriteSections:
      showSections()
    case .notifications:
      viewStore.send(.notificationsSelected)
    }
  }

  private func item(at indexPath: IndexPath) -> SettingsItem {
    sections[indexPath.section].items[indexPath.row]
  }

  private func accessoryType(for item: SettingsItem) -> UITableViewCell.AccessoryType {
    switch item {
    case .exportDatabase:
      return .none
    case .favoriteRegion, .favoriteSections, .notifications:
      return .disclosureIndicator
    }
  }

  private func attributes(withForegroundColor foregroundColor: UIColor) -> [NSAttributedString.Key: Any] {
    let font = FontFamily.NYTFranklin.medium.font(size: 16)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.maximumLineHeight = font.pointSize
    paragraphStyle.minimumLineHeight = font.pointSize
    return [
      .font: font,
      .foregroundColor: foregroundColor,
      .paragraphStyle: paragraphStyle,
    ]
  }

  private func text(for item: SettingsItem) -> String {
    switch item {
    case .exportDatabase:
      return L10n.Settings.exportDatabase
    case .favoriteRegion:
      return L10n.Settings.region
    case .favoriteSections:
      return L10n.Settings.sections
    case .notifications:
      return L10n.Settings.notifications
    }
  }

  private func secondaryText(for item: SettingsItem) -> String? {
    switch item {
    case .favoriteRegion:
      return viewStore.favoriteRegion?.title
    case .favoriteSections:
      return L10n.SettingsPlurals.sectionsValue(viewStore.favoriteSections.count)
    case .exportDatabase, .notifications:
      return nil
    }
  }

  private func showRegion() {
    let regionViewController = SettingsRegionViewController()
    self.regionViewController = regionViewController
    regionViewController.configuration = .init(state: viewStore.state)
    regionViewController.onDismiss = { [weak self, weak regionViewController] in
      if let self, let regionViewController {
        let feed = regionViewController.configuration.selectedFeed
        if feed != self.viewStore.favoriteRegion {
          self.viewStore.send(.favoriteRegionSelected(feed))
        }
      }
    }
    show(regionViewController, sender: nil)
  }

  private func showSections() {
    let sectionsViewController = SettingsSectionsViewController()
    sectionsViewController.configuration = .init(state: viewStore.state)
    sectionsViewController.onDismiss = { [weak self, weak sectionsViewController] in
      if let self, let sectionsViewController {
        let sections = sectionsViewController.configuration.selectedFeeds
        if sections != Set(self.viewStore.favoriteSections) {
          self.viewStore.send(.favoriteSectionsSelected(Array(sections)))
        }
      }
    }
    show(sectionsViewController, sender: nil)
  }

  private func showShare(with url: URL) {
    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
      for indexPath in self?.tableView.indexPathsForVisibleRows ?? [] {
        self?.tableView.deselectRow(at: indexPath, animated: true)
      }
    }
    present(activityViewController, animated: true)
  }
}

private extension RegionsConfiguration {
  init(state: SettingsReducer.State) {
    feeds = state.regions
    selectedFeed = state.favoriteRegion
  }
}

private extension SectionsConfiguration {
  init(state: SettingsReducer.State) {
    feeds = state.sections
    selectedFeeds = Set(state.favoriteSections)
  }
}

private extension SettingsReducer.State {
  var applicationIdentifiers: String? {
    if let applicationVersion, let applicationBuild {
      return "\(applicationVersion) (\(applicationBuild))"
    } else {
      return applicationVersion ?? applicationBuild
    }
  }
}

private final class SettingsFooter: UITableViewHeaderFooterView {
  static let reuseIdentifier = String(describing: SettingsFooter.self)
}
