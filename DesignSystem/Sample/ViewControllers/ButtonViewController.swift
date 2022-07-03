import AsyncDisplayKit
import DesignSystem

final class ButtonViewController: ASDKViewController<ASDisplayNode> {
  private var buttonNodes: [ButtonNode] = []

  override init() {
    super.init(node: .init())

    let buttonConfigurations: [ButtonNode.Configuration] = [.primary, .secondary, .text]
    let buttonNodes = buttonConfigurations.map { configuration in
      let node = ButtonNode(configuration: configuration)
      node.addTarget(self, action: #selector(buttonTapped), forControlEvents: .touchUpInside)
      node.setTitle("Something", for: .normal)
      return node
    }
    self.buttonNodes = buttonNodes

    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 16,
          justifyContent: .center,
          alignItems: .center,
          children: buttonNodes.map { node in
            node.styled { style in
              style.width = .init(unit: .fraction, value: 1)
            }
          }
        )
      )
    }
    node.onDidLoad { node in
      let tapAction = #selector(ButtonViewController.backgroundTapped)
      let tap = UITapGestureRecognizer(target: self, action: tapAction)
      node.view.addGestureRecognizer(tap)
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func backgroundTapped() {
    for buttonNode in buttonNodes {
      buttonNode.isEnabled.toggle()
    }
  }

  @objc private func buttonTapped() {
    print(#function, Date())
  }
}
