import AsyncDisplayKit
import DesignSystem
import IGListSwiftKit

struct ThatsAllSectionConfiguration: ListIdentifiable {
  let identifier = "com.mttcrsp.ansia.today.thatsall"
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

final class ThatsAllSectionController: ListSectionController {
  func nodeBlockForItem(at _: Int) -> ASCellNodeBlock {
    {
      let textNode = ASTextNode()
      textNode.attributedText = NSAttributedString(
        string: L10n.Today.thatsAll,
        attributes: [
          .font: FontFamily.NYTCheltenham.medium.font(size: 18),
          .foregroundColor: DesignSystemAsset.label.color,
        ]
      )

      let node = ASCellNode()
      node.automaticallyManagesSubnodes = true
      node.style.width = .init(unit: .fraction, value: 1)
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16),
          child: textNode
        )
      }
      return node
    }
  }
}

extension ThatsAllSectionController: ASSectionController {
  override func sizeForItem(at index: Int) -> CGSize {
    ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
}
