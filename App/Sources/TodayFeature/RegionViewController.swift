import AsyncDisplayKit
import Core
import DesignSystem

final class RegionViewController: ASDKViewController<ActionableNode> {
  var onConfirmTap: () -> Void = {}
  var onDismissTap: () -> Void = {}

  var configuration = RegionsConfiguration() {
    didSet { didChangeConfiguration() }
  }

  private let confirmNode: ButtonNode
  private let regionsTableView: RegionsView

  init(configuration: RegionsConfiguration) {
    self.configuration = configuration

    let confirmNode = ButtonNode(configuration: .primary)
    self.confirmNode = confirmNode

    let regionsTableView = RegionsView()
    regionsTableView.configuration = configuration
    self.regionsTableView = regionsTableView

    let regionsNode = ASDisplayNode(viewBlock: { regionsTableView })
    super.init(node: .init(contentNode: regionsNode, actionsNode: confirmNode))

    regionsTableView.configuration = configuration
    regionsTableView.onFeedSelected = { [weak self] feed in
      self?.configuration.selectedFeed = feed
      self?.confirmNode.isEnabled = true
    }

    let confirmTitle = L10n.Onboarding.confirm
    let confirmAction = #selector(didTapConfirm)
    confirmNode.accessibilityIdentifier = "confirm_button"
    confirmNode.addTarget(self, action: confirmAction, forControlEvents: .touchUpInside)
    confirmNode.isEnabled = shouldEnableConfirm
    confirmNode.setTitle(confirmTitle, for: .normal)

    let dismissAction = #selector(didTapDismiss)
    let dismissItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: dismissAction)
    dismissItem.accessibilityIdentifier = "dismiss_button"
    dismissItem.accessibilityLabel = L10n.RegionSelection.dismiss
    navigationItem.leftBarButtonItem = dismissItem
    navigationItem.standardAppearance = .opaque

    title = L10n.RegionSelection.title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    regionsTableView.contentInset.bottom = node.preferredLayoutMargins.bottom
  }

  private func didChangeConfiguration() {
    regionsTableView.configuration = configuration
    confirmNode.isEnabled = shouldEnableConfirm
  }

  @objc private func didTapConfirm() {
    onConfirmTap()
  }

  @objc private func didTapDismiss() {
    onDismissTap()
  }

  private var shouldEnableConfirm: Bool {
    configuration.selectedFeed != nil
  }
}
