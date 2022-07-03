import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct MoreFeedsSectionConfiguration: ListIdentifiable {
  let identifier = "com.mttcrsp.ansia.more.feeds"
  let feeds: [Feed]
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

final class MoreFeedsSectionController: ListValueSectionController<MoreFeedsSectionConfiguration> {
  var onFeedSelected: (Feed) -> Void = { _ in }

  override init() {
    super.init()
    inset.top = 8
  }

  override func numberOfItems() -> Int {
    value.feeds.count
  }

  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let feed = value.feeds[index]
    return {
      let fontSize: CGFloat = 16
      let font = FontFamily.NYTFranklin.bold.font(size: fontSize)
      let color = DesignSystemAsset.label.color

      let textNode = ASTextNode()
      textNode.attributedText = .init(
        string: feed.title,
        attributes: [
          .font: font,
          .foregroundColor: color,
          .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = fontSize
            paragraphStyle.minimumLineHeight = fontSize
            return paragraphStyle
          }(),
        ]
      )

      let imageNode = ASImageNode()
      imageNode.style.width = .init(unit: .points, value: 13)
      imageNode.style.height = .init(unit: .points, value: fontSize)
      imageNode.onDidLoad { node in
        if let imageNode = node as? ASImageNode {
          imageNode.image = .init(systemName: "chevron.right")?
            .withTintColor(color, renderingMode: .alwaysTemplate)
            .withConfiguration(UIImage.SymbolConfiguration(font: font))
        }
      }

      let separatorNode = SeparatorNode()

      let node = CellNode()
      node.accessibilityIdentifier = "more_feed_\(feed.slug)"
      node.automaticallyManagesSubnodes = true
      node.style.width = .init(unit: .fraction, value: 1)
      node.layoutSpecBlock = { _, _ in
        ASStackLayoutSpec(
          direction: .vertical,
          spacing: 0,
          justifyContent: .start,
          alignItems: .stretch,
          children: [
            ASInsetLayoutSpec(
              insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
              child: ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 16,
                justifyContent: .spaceBetween,
                alignItems: .center,
                children: [textNode, imageNode]
              )
            ),
            ASInsetLayoutSpec(
              insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0),
              child: separatorNode
            ),
          ]
        )
      }
      return node
    }
  }

  override func didSelectItem(at index: Int) {
    onFeedSelected(value.feeds[index])
  }
}

extension MoreFeedsSectionController: ASSectionController {
  override func sizeForItem(at index: Int) -> CGSize {
    ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
}
