import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct MoreArticlesSectionConfiguration: ListIdentifiable {
  let identifier: String
  var title: String
  var action: String
  var articles: [Article] = []
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

final class MoreArticlesSectionController: ListValueSectionController<MoreArticlesSectionConfiguration> {
  var onArticleSelected: (Article) -> Void = { _ in }
  var onMoreTap: () -> Void = {}

  override init() {
    super.init()
    supplementaryViewSource = self
  }

  override func numberOfItems() -> Int {
    1
  }

  func nodeBlockForItem(at _: Int) -> ASCellNodeBlock {
    let articles = value.articles
    return {
      let articlesNode = HorizontalArticlesNode(configuration: .init(articles: articles))
      articlesNode.style.width = .init(unit: .fraction, value: 1)
      articlesNode.onArticleTap = { [weak self] article in
        self?.onArticleSelected(article)
      }

      let node = CellNode()
      node.automaticallyManagesSubnodes = true
      node.layoutSpecBlock = { _, _ in
        ASWrapperLayoutSpec(layoutElement: articlesNode)
      }
      return node
    }
  }
}

extension MoreArticlesSectionController: ListSupplementaryViewSource, ASSupplementaryNodeSource {
  func supportedElementKinds() -> [String] {
    [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter]
  }

  func nodeBlockForSupplementaryElement(ofKind elementKind: String, at _: Int) -> ASCellNodeBlock {
    let title = value.title
    switch elementKind {
    case UICollectionView.elementKindSectionHeader:
      return {
        let node = ASCellNode()
        node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
        node.automaticallyManagesSubnodes = true
        node.layoutSpecBlock = { _, _ in
          ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 20, left: 16, bottom: 24, right: 16),
            child: HeaderNode(
              configuration: .init(title: title, uppercased: false, style: .large)
            )
          )
        }
        return node
      }
    case UICollectionView.elementKindSectionFooter:
      let action = value.action
      return {
        let disclosureNode = DisclosureButtonNode(
          configuration: .init(title: action)
        )
        disclosureNode.hitTestSlop = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -150)
        disclosureNode.onTap = { [weak self] in
          self?.onMoreTap()
        }

        let node = CellNode()
        node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
        node.automaticallyManagesSubnodes = true
        node.layoutSpecBlock = { _, _ in
          ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 24, left: 16, bottom: 0, right: 16),
            child: ASStackLayoutSpec(
              direction: .vertical,
              spacing: 24,
              justifyContent: .center,
              alignItems: .stretch,
              children: [
                ASCenterLayoutSpec(
                  horizontalPosition: .start,
                  verticalPosition: .center,
                  sizingOption: .minimumSize,
                  child: disclosureNode
                ),
                SeparatorNode(configuration: .prominent),
              ]
            )
          )
        }
        return node
      }
    default:
      return ASCellNode.init
    }
  }
}

extension MoreArticlesSectionController: ASSectionController {
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
