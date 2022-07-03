import AsyncDisplayKit
import DesignSystem

final class SeparatorViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    super.init(node: .init())

    let separatorConfigurations: [SeparatorNode.Configuration] = [.default, .prominent]
    let separatorNodes = separatorConfigurations.map(SeparatorNode.init)

    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 80,
          justifyContent: .center,
          alignItems: .center,
          children: separatorNodes
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func buttonTapped() {
    print(#function, Date())
  }
}
