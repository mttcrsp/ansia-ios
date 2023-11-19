import AsyncDisplayKit
import Combine
import ComposableArchitecture
import Core
import DesignSystem

final class MoreViewController: ASDKViewController<ASCollectionNode> {
  var onArticleSelected: (Article) -> Void = { _ in }
  var onBookmarksTap: () -> Void = {}

  private lazy var adapter: ListAdapter =
    .init(updater: ListAdapterUpdater(), viewController: self)
  private let store: StoreOf<MoreReducer>
  private let viewStore: ViewStoreOf<MoreReducer>
  private var cancellables: Set<AnyCancellable> = []
  private weak var resultsViewController: ResultsViewController?
  private weak var sectionViewController: ArticlesViewController?

  init(store: StoreOf<MoreReducer>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })

    let collectionLayout = UICollectionViewFlowLayout()
    let collectionNode = ASCollectionNode(collectionViewLayout: collectionLayout)
    collectionNode.backgroundColor = DesignSystemAsset.background.color
    super.init(node: collectionNode)

    let settingsTitle = L10n.More.settings
    let settingsImage = UIImage(systemName: "gearshape")
    let settingsItem = UIBarButtonItem(
      primaryAction: .init(title: settingsTitle, image: settingsImage) { [weak self] _ in
        self?.viewStore.send(.settingsTapped)
      }
    )

    let resultsViewController = ResultsViewController()
    resultsViewController.onArticleSelected = { [weak self] article in
      self?.viewStore.send(.articleSelected(article))
    }
    self.resultsViewController = resultsViewController

    adapter.setASDKCollectionNode(node)
    adapter.dataSource = self
    navigationItem.rightBarButtonItem = settingsItem
    navigationItem.standardAppearance = .prominent
    navigationItem.searchController = UISearchController(searchResultsController: resultsViewController)
    navigationItem.searchController?.searchBar.searchTextField.placeholder = L10n.Search.prompt
    navigationItem.searchController?.searchResultsUpdater = self

    tabBarItem = UITabBarItem(
      title: L10n.More.tab,
      image: UIImage(systemName: "magnifyingglass"),
      selectedImage: UIImage(systemName: "magnifyingglass")
    )
    title = L10n.More.tab
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    struct MoreItems: Equatable {
      let bookmarks: [Bookmark]
      let feeds: [Feed]
      let recents: [Recent]
      init(state: MoreReducer.State) {
        bookmarks = state.bookmarks
        feeds = state.feeds
        recents = state.recents
      }
    }

    viewStore.publisher
      .map(MoreItems.init)
      .removeDuplicates()
      .sink { [weak self] _ in
        self?.adapter.performUpdates(animated: false)
      }
      .store(in: &cancellables)

    viewStore.publisher.resultsArticles
      .removeDuplicates()
      .sink { [weak self] articles in
        self?.resultsViewController?.configuration.articles = articles
      }
      .store(in: &cancellables)

    viewStore.publisher.sectionArticles
      .removeDuplicates()
      .sink { [weak self] articles in
        self?.sectionViewController?.configuration.articles = articles
      }
      .store(in: &cancellables)

    store.scope(state: \.article, action: MoreReducer.Action.article)
      .ifLet { [weak self] store in
        let articleViewController = ArticleViewController(store: store)
        self?.show(articleViewController, sender: nil)
      }
      .store(in: &cancellables)

    viewStore.send(.didLoad)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    node.deselectSelectedItems()
  }

  private func showBookmarksList() {
    let bookmarksViewController = ArticlesViewController(configuration: .init(
      title: L10n.More.bookmarks,
      articles: viewStore.bookmarks.map(\.article)
    ))
    bookmarksViewController.onArticleSelected = { [weak self] article in
      self?.viewStore.send(.articleSelected(article))
    }
    show(bookmarksViewController, sender: nil)
  }

  private func showRecentsList() {
    let recentsViewController = ArticlesViewController(configuration: .init(
      title: L10n.More.recents,
      articles: viewStore.recents.map(\.article)
    ))
    recentsViewController.onArticleSelected = { [weak self] article in
      self?.viewStore.send(.articleSelected(article))
    }
    show(recentsViewController, sender: nil)
  }

  private func showFeed(_ feed: Feed) {
    let sectionViewController = ArticlesViewController(
      configuration: .init(title: feed.title)
    )
    sectionViewController.stylingBlock = { element in
      let calendar = Locale.italian.calendar
      if element.index == 0 {
        return .fullWidth
      } else if calendar.isRecent(element.article.publishedAt, delta: .init(hour: -3)) {
        return .large
      } else if calendar.isDateInToday(element.article.publishedAt) {
        return .default
      } else {
        return .small
      }
    }
    sectionViewController.onArticleSelected = { [weak self] article in
      self?.viewStore.send(.articleSelected(article))
    }
    sectionViewController.onDismiss = { [weak self] in
      self?.viewStore.send(.sectionDeselected)
    }
    self.sectionViewController = sectionViewController
    show(sectionViewController, sender: nil)
  }

  func scrollToTop() {
    var point = CGPoint.zero
    point.y -= node.view.adjustedContentInset.top
    point.x -= node.view.adjustedContentInset.left
    node.setContentOffset(point, animated: true)
  }
}

extension MoreViewController: ListAdapterDataSource {
  func listAdapter(_: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    if let configuration = MoreArticlesSectionConfiguration(diffable: object) {
      let controller = MoreArticlesSectionController()
      controller.onArticleSelected = { [weak self] article in
        self?.viewStore.send(.articleSelected(article))
      }
      controller.onMoreTap = { [weak self] in
        switch configuration.identifier {
        case MoreArticlesSectionConfiguration.bookmarksIdentifier:
          self?.showBookmarksList()
        case MoreArticlesSectionConfiguration.recentsIdentifier:
          self?.showRecentsList()
        case _:
          return
        }
      }
      return controller
    }

    let controller = MoreFeedsSectionController()
    controller.onFeedSelected = { [weak self] feed in
      self?.showFeed(feed)
      self?.viewStore.send(.sectionSelected(feed))
    }
    return controller
  }

  func objects(for _: ListAdapter) -> [ListDiffable] {
    var diffable: [ListDiffable] = []

    if !viewStore.bookmarks.isEmpty {
      diffable.append(
        MoreArticlesSectionConfiguration(
          identifier: MoreArticlesSectionConfiguration.bookmarksIdentifier,
          title: L10n.More.bookmarks,
          action: L10n.More.allBookmarks,
          articles: viewStore.bookmarks.map(\.article)
        ).diffable()
      )
    }

    if !viewStore.recents.isEmpty {
      diffable.append(
        MoreArticlesSectionConfiguration(
          identifier: MoreArticlesSectionConfiguration.recentsIdentifier,
          title: L10n.More.recents,
          action: L10n.More.allRecents,
          articles: viewStore.recents.map(\.article)
        ).diffable()
      )
    }

    diffable.append(
      MoreFeedsSectionConfiguration(
        feeds: viewStore.feeds
      ).diffable()
    )
    return diffable
  }

  func emptyView(for _: ListAdapter) -> UIView? {
    nil
  }
}

extension MoreViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    viewStore.send(.queryChanged(searchController.searchBar.text ?? ""))
  }
}

private extension MoreArticlesSectionConfiguration {
  static let bookmarksIdentifier = "bookmarks"
  static let recentsIdentifier = "recents"
}
