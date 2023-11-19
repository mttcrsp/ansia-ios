import AsyncDisplayKit
import Core
import DesignSystem

final class HorizontalArticlesNode: ASDisplayNode {
  struct Configuration {
    let articles: [Article]
  }

  var onArticleTap: (Article) -> Void = { _ in } {
    didSet { didChangeArticleTapHandler() }
  }

  private let column1: HorizontalArticlesColumnNode
  private let column2: HorizontalArticlesColumnNode
  private let column3: HorizontalArticlesColumnNode

  init(configuration: Configuration) {
    column1 = HorizontalArticlesColumnNode(configuration: .init(
      article1: configuration.article(at: 0),
      article2: configuration.article(at: 1)
    ))
    column2 = HorizontalArticlesColumnNode(configuration: .init(
      article1: configuration.article(at: 2),
      article2: configuration.article(at: 3)
    ))
    column3 = HorizontalArticlesColumnNode(configuration: .init(
      article1: configuration.article(at: 4),
      article2: configuration.article(at: 5)
    ))

    super.init()

    for column in columns {
      column.hitTestSlop = .init(top: -20, left: -20, bottom: -20, right: -20)
      column.onArticleTap = onArticleTap
    }

    let scrollNode = ASScrollNode()
    scrollNode.automaticallyManagesContentSize = true
    scrollNode.automaticallyManagesSubnodes = true
    scrollNode.scrollableDirections = [.left, .right]
    scrollNode.layoutSpecBlock = { [unowned self] _, _ in
      ASStackLayoutSpec(
        direction: .horizontal,
        spacing: 16,
        justifyContent: .start,
        alignItems: .start,
        children: columns
          .filter { node in
            !node.configuration.isEmpty
          }
          .map { column in
            column.styled { style in
              style.width = .init(unit: .points, value: 300)
            }
          }
      )
    }
    scrollNode.onDidLoad { node in
      if let scrollView = node.view as? UIScrollView {
        scrollView.decelerationRate = .fast
        scrollView.delegate = self
        scrollView.contentInset.left = 16
        scrollView.contentInset.right = 16
        scrollView.showsHorizontalScrollIndicator = false
      }
    }

    automaticallyManagesSubnodes = true
    layoutSpecBlock = { _, _ in
      ASCenterLayoutSpec(
        horizontalPosition: .center,
        verticalPosition: .center,
        sizingOption: .minimumHeight,
        child: scrollNode
      )
    }
  }

  private var columns: [HorizontalArticlesColumnNode] {
    [column1, column2, column3]
  }

  private func didChangeArticleTapHandler() {
    for column in columns {
      column.onArticleTap = onArticleTap
    }
  }
}

extension HorizontalArticlesNode: UIScrollViewDelegate {
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if velocity.x > 0 {
      for column in columns {
        let columnX = column.frame.minX - 16
        if columnX > scrollView.contentOffset.x {
          targetContentOffset.pointee.x = columnX
          break
        }
      }
    } else if velocity.x < 0 {
      for column in columns.reversed() {
        let columnX = column.frame.minX - 16
        if columnX < scrollView.contentOffset.x {
          targetContentOffset.pointee.x = columnX
          break
        }
      }
    } else {
      var targetColumnX: CGFloat = 0, minDistance: CGFloat = .greatestFiniteMagnitude
      for column in columns {
        let columnX = column.frame.minX - 16
        let distance = abs(targetContentOffset.pointee.x - columnX)
        if distance < minDistance {
          minDistance = distance
          targetColumnX = columnX
        }
      }
      targetContentOffset.pointee.x = targetColumnX
    }
  }
}

private extension HorizontalArticlesNode.Configuration {
  func article(at index: Int) -> Article? {
    articles.indices.contains(index) ? articles[index] : nil
  }
}

private final class HorizontalArticlesColumnNode: ASDisplayNode {
  struct Configuration {
    let article1: Article?
    let article2: Article?
  }

  var onArticleTap: (Article) -> Void = { _ in }

  private let articleNode1: ArticleNode?
  private let articleNode2: ArticleNode?
  let configuration: Configuration

  init(configuration: Configuration) {
    self.configuration = configuration

    let makeSmallArticleNode: (Article) -> ArticleNode = { article in
      ArticleNode(configuration: .init(article: article, style: .small))
    }
    articleNode1 = configuration.article1.map(makeSmallArticleNode)
    articleNode2 = configuration.article2.map(makeSmallArticleNode)

    super.init()

    automaticallyManagesSubnodes = true

    for node in [articleNode1, articleNode2] {
      node?.hitTestSlop = .init(top: -20, left: -20, bottom: -20, right: -20)
      node?.onDidLoad { [weak self] node in
        let pressAction = #selector(HorizontalArticlesColumnNode.didPressArticle)
        let press = UILongPressGestureRecognizer(target: self, action: pressAction)
        press.minimumPressDuration = 0

        let tapAction = #selector(HorizontalArticlesColumnNode.didTapArticle)
        let tap = UITapGestureRecognizer(target: self, action: tapAction)

        for recognizer in [press, tap] {
          recognizer.delegate = self
          node.view.addGestureRecognizer(recognizer)
        }
      }
    }
  }

  override func layoutSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .vertical,
      spacing: 16,
      justifyContent: .start,
      alignItems: .stretch,
      children: [articleNode1, articleNode2].compactMap { $0 }
    )
  }

  @objc private func didPressArticle(_ sender: UILongPressGestureRecognizer) {
    sender.view?.alpha = sender.state == .began ? 0.5 : 1
  }

  @objc private func didTapArticle(_ sender: UITapGestureRecognizer) {
    var article: Article?
    if let node = articleNode1, node.view == sender.view {
      article = configuration.article1
    } else if let node = articleNode2, node.view == sender.view {
      article = configuration.article2
    }

    if let article {
      onArticleTap(article)
    }
  }
}

extension HorizontalArticlesColumnNode: UIGestureRecognizerDelegate {
  func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
    true
  }
}

private extension HorizontalArticlesColumnNode.Configuration {
  var isEmpty: Bool {
    article1 == nil && article2 == nil
  }
}
