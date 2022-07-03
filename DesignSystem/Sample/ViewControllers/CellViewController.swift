import AsyncDisplayKit
import DesignSystem

final class CellViewController: ASDKViewController<ASCollectionNode> {
  override init() {
    let collectionLayout = UICollectionViewFlowLayout()
    let collectionNode = ASCollectionNode(collectionViewLayout: collectionLayout)
    super.init(node: collectionNode)
    node.backgroundColor = DesignSystemAsset.background.color
    node.dataSource = self
    node.delegate = self
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension CellViewController: ASCollectionDataSource {
  func collectionNode(_: ASCollectionNode, numberOfItemsInSection _: Int) -> Int {
    1
  }

  func collectionNode(_: ASCollectionNode, nodeBlockForItemAt _: IndexPath) -> ASCellNodeBlock {
    {
      let separatorNode1 = SeparatorNode()
      let separatorNode2 = SeparatorNode()
      let textNode = ASTextNode()
      textNode.attributedText = .init(
        string: "Something",
        attributes: [
          .font: FontFamily.NYTFranklin.medium.font(size: 16),
          .foregroundColor: DesignSystemAsset.label.color,
        ]
      )

      let node = CellNode()
      node.automaticallyManagesSubnodes = true
      node.style.width = .init(unit: .fraction, value: 1)
      node.layoutSpecBlock = { _, _ in
        ASStackLayoutSpec(
          direction: .vertical,
          spacing: 0,
          justifyContent: .start,
          alignItems: .stretch,
          children: [
            separatorNode1,
            ASInsetLayoutSpec(
              insets: .init(top: 16, left: 16, bottom: 16, right: 16),
              child: textNode
            ),
            separatorNode2,
          ]
        )
      }
      return node
    }
  }
}

extension CellViewController: ASCollectionDelegate {
  func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
    collectionNode.deselectItem(at: indexPath, animated: true)
  }
}
