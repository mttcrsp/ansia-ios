import Combine
import ComposableArchitecture
import DesignSystem
import UIKit

final class NotificationsViewController: UITableViewController {
  private enum Item: Equatable {
    case all
    case videoDay
    case videoNight
  }

  private struct Section: Equatable {
    let items: [Item]
    static let all = Section(items: [.all])
    static let detailed = Section(items: [
      .videoDay,
      .videoNight,
    ])
  }

  private lazy var allSwitch = UISwitch()
  private lazy var videoDaySwitch = UISwitch()
  private lazy var videoNightSwitch = UISwitch()
  private let viewStore: ViewStoreOf<NotificationsReducer>
  private var cancellables: Set<AnyCancellable> = []
  private var sections: [Section] = []

  init(store: StoreOf<NotificationsReducer>) {
    viewStore = ViewStore(store)
    super.init(style: .grouped)
    navigationItem.standardAppearance = .opaque
    title = L10n.Settings.notifications
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    allSwitch.accessibilityIdentifier = "all_switch"
    videoDaySwitch.accessibilityIdentifier = "video_day_switch"
    videoNightSwitch.accessibilityIdentifier = "video_night_switch"

    tableView.allowsSelection = false
    tableView.backgroundColor = DesignSystemAsset.background.color
    tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)

    for `switch` in switches {
      `switch`.addTarget(self, action: #selector(didToggle), for: .valueChanged)
      `switch`.onTintColor = DesignSystemAsset.fill.color
    }

    viewStore.publisher.notificationsStatus
      .sink { [weak self] status in
        self?.didChangeStatus(status)
      }
      .store(in: &cancellables)

    viewStore.publisher.shouldReload
      .sink { [weak self] _ in
        if let self {
          self.didChangeStatus(
            self.viewStore.notificationsStatus
          )
        }
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

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = sections[indexPath.section].items[indexPath.row]
    let font = FontFamily.NYTFranklin.medium.font(size: 16)
    let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as! SettingsCell
    var configuration = cell.defaultContentConfiguration()
    configuration.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    configuration.attributedText = .init(
      string: text(for: item),
      attributes: [
        .font: font,
        .foregroundColor: DesignSystemAsset.label.color.cgColor,
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = font.pointSize
          paragraphStyle.minimumLineHeight = font.pointSize
          return paragraphStyle
        }(),
      ]
    )
    cell.accessoryView = `switch`(for: item)
    cell.contentConfiguration = configuration
    return cell
  }

  private var switches: [UISwitch] {
    [allSwitch, videoDaySwitch, videoNightSwitch]
  }

  @objc private func didToggle(_ sender: UISwitch) {
    let enabled = sender.isOn
    switch sender {
    case allSwitch:
      viewStore.send(.allNotificationsToggled(enabled))
    case videoDaySwitch:
      viewStore.send(.videoDayToggled(enabled))
    case videoNightSwitch:
      viewStore.send(.videoNightToggled(enabled))
    default:
      break
    }
  }

  private func didChangeStatus(_ status: NotificationsStatus) {
    switch status {
    case .disabled:
      for `switch` in switches {
        `switch`.setOn(false, animated: true)
      }
    case let .enabled(configuration):
      allSwitch.setOn(true, animated: true)
      videoDaySwitch.setOn(configuration.isVideoDayEnabled, animated: true)
      videoNightSwitch.setOn(configuration.isVideoNightEnabled, animated: true)
    }

    let newSections = sections(for: status)
    let oldSections = sections
    if newSections != oldSections {
      sections = newSections
      tableView.reloadData()
    }
  }

  private func sections(for status: NotificationsStatus) -> [Section] {
    switch status {
    case .disabled:
      return [.all]
    case .enabled:
      return [.all, .detailed]
    }
  }

  private func `switch`(for item: Item) -> UISwitch {
    switch item {
    case .all:
      return allSwitch
    case .videoDay:
      return videoDaySwitch
    case .videoNight:
      return videoNightSwitch
    }
  }

  private func text(for item: Item) -> String {
    switch item {
    case .all:
      return L10n.SettingsNotifications.all
    case .videoDay:
      return L10n.SettingsNotifications.videoDay
    case .videoNight:
      return L10n.SettingsNotifications.videoNight
    }
  }
}
