import Core
import DesignSystem
import UIKit

final class SettingsRegionViewController: UIViewController {
  var configuration: RegionsConfiguration {
    get { regionsTableView.configuration }
    set { regionsTableView.configuration = newValue }
  }

  var onDismiss: () -> Void = {}

  private lazy var regionsTableView = RegionsView()

  override func loadView() {
    view = regionsTableView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.standardAppearance = .opaque
    regionsTableView.backgroundColor = DesignSystemAsset.background.color
    regionsTableView.configuration = configuration
    regionsTableView.onFeedSelected = { [weak self] feed in
      self?.configuration.selectedFeed = feed
    }
    title = L10n.Settings.region
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      onDismiss()
    }
  }
}
