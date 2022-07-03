import AsyncDisplayKit
import DesignSystem

final class DisclosureViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    super.init(node: .init())

    let disclosureNode = DisclosureButtonNode(configuration: .init(title: "Something"))
    disclosureNode.addTarget(self, action: #selector(tapped), forControlEvents: .touchUpInside)

    node.automaticallyManagesSubnodes = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { _, _ in
      ASCenterLayoutSpec(
        horizontalPosition: .center,
        verticalPosition: .center,
        sizingOption: .minimumSize,
        child: disclosureNode
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func tapped() {
    print(#function, Date())
  }
}
