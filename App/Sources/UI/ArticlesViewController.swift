import AsyncDisplayKit
import Core
import DesignSystem
import IGListKit

class ArticlesViewController: ASDKViewController<ASCollectionNode> {
  struct Configuration {
    var allowsRefreshing = false
    var animatesUpdates = true
    var title: String?
    var articles: [Article] = []
  }

  var onArticleSelected: (Article) -> Void = { _ in }
  var onDismiss: () -> Void = {}
  var onRefreshToggled: () -> Void = {}
  var stylingBlock: ArticlesSectionController.StylingBlock = { _ in .default }

  private lazy var adapter: ListAdapter =
    .init(updater: ListAdapterUpdater(), viewController: self)

  private lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(didRefresh), for: .valueChanged)
    return refreshControl
  }()

  var configuration: Configuration {
    didSet { didChangeConfiguration() }
  }

  init(configuration: Configuration) {
    self.configuration = configuration

    let collectionLayout = UICollectionViewFlowLayout()
    let collectionNode = ASCollectionNode(collectionViewLayout: collectionLayout)
    super.init(node: collectionNode)
    adapter.setASDKCollectionNode(node)
    adapter.dataSource = self
    hidesBottomBarWhenPushed = true
    title = configuration.title
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    node.backgroundColor = DesignSystemAsset.background.color
    if configuration.allowsRefreshing {
      view.addSubview(refreshControl)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    node.deselectSelectedItems()
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      onDismiss()
    }
  }

  func beginRefreshing() {
    refreshControl.beginRefreshing()
  }

  func endRefreshing() {
    refreshControl.endRefreshing()
  }

  @objc private func didRefresh() {
    onRefreshToggled()
  }

  private func didChangeConfiguration() {
    adapter.performUpdates(animated: configuration.animatesUpdates)
  }
}

extension ArticlesViewController: ListAdapterDataSource {
  func listAdapter(_: ListAdapter, sectionControllerFor _: Any) -> ListSectionController {
    let controller = ArticlesSectionController()
    controller.onArticleSelected = onArticleSelected
    controller.stylingBlock = stylingBlock
    return controller
  }

  func objects(for _: ListAdapter) -> [ListDiffable] {
    [ArticlesSectionConfiguration(identifier: "main", articles: configuration.articles).diffable()]
  }

  func emptyView(for _: ListAdapter) -> UIView? {
    nil
  }
}
