import AsyncDisplayKit
import Core
import DesignSystem

final class ResultsViewController: CrossDissolveViewController {
  struct Configuration {
    var articles: [Article]?
  }

  var configuration = Configuration() {
    didSet { didChangeConfiguration() }
  }

  var onArticleSelected: (Article) -> Void {
    get { articlesViewController.onArticleSelected }
    set { articlesViewController.onArticleSelected = newValue }
  }

  private lazy var articlesViewController = ArticlesViewController(
    configuration: .init(animatesUpdates: false)
  )
  private lazy var loadingViewController = LoadingViewController()
  private lazy var noArticlesViewController = NoResultsViewController()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = DesignSystemAsset.background.color
    setContentViewController(loadingViewController, animated: true)
  }

  private func didChangeConfiguration() {
    switch configuration.articles {
    case .none:
      setContentViewController(loadingViewController, animated: true)
    case .some([]):
      setContentViewController(noArticlesViewController, animated: true)
    case let .some(articles):
      articlesViewController.configuration.articles = articles
      setContentViewController(articlesViewController, animated: true)
    }
  }
}
