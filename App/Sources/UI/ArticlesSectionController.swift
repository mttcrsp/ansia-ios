import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct ArticlesSectionConfiguration: ListIdentifiable {
  let identifier: String
  var title: String?
  var articles: [Article] = []
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

final class ArticlesSectionController: ListValueSectionController<ArticlesSectionConfiguration> {
  typealias StylingElement = (article: Article, index: Int)
  typealias StylingResult = ArticleNode.Configuration.Style
  typealias StylingBlock = (StylingElement) -> StylingResult
  var stylingBlock: StylingBlock = { _ in .default }

  override init() {
    super.init()
    supplementaryViewSource = self
  }

  override func numberOfItems() -> Int {
    value.articles.count
  }

  func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
    let article = value.articles[index]
    let articleStyle = stylingBlock((article: article, index: index))
    let articleConfiguration = ArticleNode.Configuration(article: article, style: articleStyle)
    let isLastArticle = article == value.articles.last
    let isLastSection = isLastSection
    return {
      let articleNode = ArticleNode(configuration: articleConfiguration)
      let separatorNode = SeparatorNode(configuration: isLastArticle ? .prominent : .default)
      separatorNode.isHidden = isLastArticle && isLastSection

      let node = CellNode()
      node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
      node.automaticallyManagesSubnodes = true
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: articleStyle.preferredInsets,
          child: ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .start,
            alignItems: .stretch,
            children: [
              articleNode,
              ASInsetLayoutSpec(
                insets: articleStyle.preferredSeparatorInsets,
                child: separatorNode
              ),
            ]
          ).styled { style in style.flexGrow = 1 }
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

extension ArticlesSectionController: ListSupplementaryViewSource, ASSupplementaryNodeSource {
  func supportedElementKinds() -> [String] {
    value.title != nil ? [UICollectionView.elementKindSectionHeader] : []
  }

  func nodeBlockForSupplementaryElement(ofKind _: String, at _: Int) -> ASCellNodeBlock {
    guard let title = value.title else {
      return ASCellNode.init
    }

    return {
      let node = ASCellNode()
      node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
      node.automaticallyManagesSubnodes = true
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16),
          child: HeaderNode(configuration: .init(title: title))
        )
      }
      return node
    }
  }
}

extension ArticlesSectionController: ASSectionController {
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

private extension ArticleNode.Configuration.Style {
  var preferredInsets: UIEdgeInsets {
    if case .fullWidth = self {
      return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    } else {
      return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
    }
  }

  var preferredSeparatorInsets: UIEdgeInsets {
    if case .fullWidth = self {
      return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    } else {
      return .zero
    }
  }
}
