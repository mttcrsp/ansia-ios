import AsyncDisplayKit
import Core
import DesignSystem

class OnboardingSectionsViewController: ASDKViewController<ActionableNode> {
  var onConfirmTap: () -> Void = {}
  var onDismiss: () -> Void = {}

  var configuration: SectionsConfiguration {
    get { sectionsView.configuration }
    set { sectionsView.configuration = newValue }
  }

  private let confirmNode: ButtonNode
  private let sectionsView: SectionsView

  init(configuration: SectionsConfiguration) {
    let confirmNode = ButtonNode(configuration: .primary)
    self.confirmNode = confirmNode

    let sectionsView = SectionsView()
    sectionsView.configuration = configuration
    self.sectionsView = sectionsView

    let sectionsNode = ASDisplayNode(viewBlock: { sectionsView })
    sectionsNode.backgroundColor = DesignSystemAsset.background.color
    super.init(node: .init(contentNode: sectionsNode, actionsNode: confirmNode))

    let confirmTitle = L10n.Onboarding.confirm
    let confirmAction = #selector(didTapConfirm)
    confirmNode.accessibilityIdentifier = "confirm_button"
    confirmNode.addTarget(self, action: confirmAction, forControlEvents: .touchUpInside)
    confirmNode.setTitle(confirmTitle, for: .normal)

    navigationItem.standardAppearance = .opaque
    title = L10n.RegionSelection.title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    sectionsView.contentInset.bottom = node.preferredLayoutMargins.bottom
  }

  @objc private func didTapConfirm() {
    onConfirmTap()
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      onDismiss()
    }
  }
}
