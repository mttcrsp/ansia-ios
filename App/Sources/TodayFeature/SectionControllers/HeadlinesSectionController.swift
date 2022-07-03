import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct HeadlinesSectionConfiguration {
  let identifier: String
  var title: String
  var articles: [Article] = []
}

final class HeadlinesSectionController: ListValueSectionController<HeadlinesSectionConfiguration> {
  override init() {
    super.init()
    supplementaryViewSource = self
  }

  override func numberOfItems() -> Int {
    value.articles.count
  }

  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let article = value.articles[index]
    return {
      let headlineNode = HeadlineNode(configuration: .init(article: article))
      let node = CellNode()
      node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
      node.automaticallyManagesSubnodes = true
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16),
          child: headlineNode
        )
      }
      return node
    }
  }

  var onArticleSelected: (Article) -> Void = { _ in }
  override func didSelectItem(at index: Int) {
    onArticleSelected(value.articles[index])
  }
}

extension HeadlinesSectionController: ListSupplementaryViewSource, ASSupplementaryNodeSource {
  func supportedElementKinds() -> [String] {
    [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter]
  }

  func nodeBlockForSupplementaryElement(ofKind elementKind: String, at _: Int) -> ASCellNodeBlock {
    switch elementKind {
    case UICollectionView.elementKindSectionHeader:
      let title = value.title
      return {
        let headerNode = HeaderNode(configuration: .init(title: title))
        let node = ASCellNode()
        node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
        node.automaticallyManagesSubnodes = true
        node.layoutSpecBlock = { _, _ in
          ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 16, bottom: 8, right: 16),
            child: headerNode
          )
        }
        return node
      }
    case UICollectionView.elementKindSectionFooter:
      return {
        let separatorNode = SeparatorNode(configuration: .prominent)
        let node = ASCellNode()
        node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
        node.automaticallyManagesSubnodes = true
        node.layoutSpecBlock = { _, _ in
          ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16),
            child: separatorNode
          )
        }
        return node
      }
    default:
      return ASCellNode.init
    }
  }
}

extension HeadlinesSectionController: ASSectionController {
  override func sizeForItem(at index: Int) -> CGSize {
    ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryView(ofKind: elementKind, at: index)
  }

  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    ASIGListSupplementaryViewSourceMethods.viewForSupplementaryElement(ofKind: elementKind, at: index, sectionController: self)
  }

  func sizeRangeForSupplementaryElement(ofKind elementKind: String, at _: Int) -> ASSizeRange {
    supportedElementKinds().contains(elementKind) ? ASSizeRangeUnconstrained : ASSizeRangeZero
  }
}

extension HeadlinesSectionConfiguration: ListIdentifiable {
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

private final class HeadlineNode: ASDisplayNode {
  struct Configuration {
    let article: Article
  }

  init(configuration: Configuration) {
    let font = FontFamily.NYTImperial.regular.font(size: 16)
    let lineHeight: CGFloat = 22

    let bulletNode = ASDisplayNode()
    bulletNode.backgroundColor = .label
    bulletNode.cornerRadius = 2

    let headlineNode = ASTextNode()
    headlineNode.attributedText = NSAttributedString(
      string: configuration.article.title,
      attributes: [
        .foregroundColor: DesignSystemAsset.secondaryLabel.color,
        .font: font,
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = lineHeight
          paragraphStyle.minimumLineHeight = lineHeight
          return paragraphStyle
        }(),
      ]
    )

    super.init()
    automaticallyManagesSubnodes = true
    layoutSpecBlock = { _, _ in
      ASStackLayoutSpec(
        direction: .horizontal,
        spacing: 8,
        justifyContent: .start,
        alignItems: .start,
        children: [
          ASCenterLayoutSpec(
            centeringOptions: .Y,
            child: bulletNode.styled { style in
              style.width = .init(unit: .points, value: 4)
              style.height = .init(unit: .points, value: 4)
            }
          ).styled { style in
            style.height = .init(unit: .points, value: lineHeight)
          },
          headlineNode.styled { style in
            style.flexShrink = 1
          },
        ]
      )
    }
  }
}
