import AsyncDisplayKit
import DesignSystem

final class HeaderViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    super.init(node: .init())

    let headerNodes = (1 ... 3).map { _ in
      HeaderNode(configuration: .init(title: "Something"))
    }

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
          children: headerNodes
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
