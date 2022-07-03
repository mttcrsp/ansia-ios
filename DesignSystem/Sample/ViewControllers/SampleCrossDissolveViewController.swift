import AsyncDisplayKit
import DesignSystem

final class SampleCrossDissolveViewController: CrossDissolveViewController {
  init() {
    super.init(nibName: nil, bundle: nil)

    let contentViewController1 = ContentViewController(verticalPosition: .start)
    let contentViewController2 = ContentViewController(verticalPosition: .end)
    let onTap: () -> Void = { [weak self] in
      switch self?.contentViewController {
      case contentViewController1:
        self?.setContentViewController(contentViewController2, animated: true)
      case contentViewController2:
        self?.setContentViewController(contentViewController1, animated: true)
      default:
        break
      }
    }
    contentViewController1.onTap = onTap
    contentViewController2.onTap = onTap
    setContentViewController(contentViewController1, animated: false)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class ContentViewController: ASDKViewController<ASDisplayNode> {
  var onTap = {}

  init(verticalPosition: ASRelativeLayoutSpecPosition) {
    super.init(node: .init())

    let buttonNode = ButtonNode(configuration: .primary)
    buttonNode.addTarget(self, action: #selector(tapped), forControlEvents: .touchUpInside)
    buttonNode.setTitle("Transition", for: .normal)

    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASCenterLayoutSpec(
          horizontalPosition: .center,
          verticalPosition: verticalPosition,
          sizingOption: .minimumSize,
          child: buttonNode
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func tapped() {
    onTap()
  }
}
