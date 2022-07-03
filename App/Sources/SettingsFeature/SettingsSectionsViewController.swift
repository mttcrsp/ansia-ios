import Core
import DesignSystem
import UIKit

final class SettingsSectionsViewController: UIViewController {
  var configuration: SectionsConfiguration {
    get { sectionsTableView.configuration }
    set { sectionsTableView.configuration = newValue }
  }

  var onDismiss: () -> Void = {}

  private lazy var sectionsTableView = SectionsView()

  override func loadView() {
    view = sectionsTableView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.standardAppearance = .opaque
    sectionsTableView.backgroundColor = DesignSystemAsset.background.color
    sectionsTableView.configuration = configuration
    title = L10n.Settings.sections
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      onDismiss()
    }
  }
}
