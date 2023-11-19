import AsyncDisplayKit
import Combine
import ComposableArchitecture
import Core
import DesignSystem

class TodayViewController: ASDKViewController<ASCollectionNode> {
  private weak var regionViewController: RegionViewController?

  private lazy var adapter: ListAdapter =
    .init(updater: ListAdapterUpdater(), viewController: self)

  private lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(didRefresh), for: .valueChanged)
    return refreshControl
  }()

  private let store: StoreOf<TodayReducer>
  private let viewStore: ViewStoreOf<TodayReducer>
  private var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<TodayReducer>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })

    let collectionLayout = UICollectionViewFlowLayout()
    let collectionNode = ASCollectionNode(collectionViewLayout: collectionLayout)
    super.init(node: collectionNode)

    node.accessibilityIdentifier = "today_collection"
    node.backgroundColor = DesignSystemAsset.background.color
    node.onDidLoad { [weak self] node in
      if let self, let node = node as? ASCollectionNode {
        node.view.addSubview(self.refreshControl)
      }
    }

    adapter.setASDKCollectionNode(node)
    adapter.dataSource = self
    navigationItem.standardAppearance = .prominent
    tabBarItem = UITabBarItem(
      title: L10n.Today.tab,
      image: UIImage(systemName: "heart.text.square"),
      selectedImage: UIImage(systemName: "heart.text.square.fill")
    )
    title = L10n.Today.tab
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    struct Items: Equatable {
      let canShowRegionSelection: Bool
      let groups: TodayGroups
      let showsVideoOnboarding: Bool
      let video: Video?
      init(state: TodayReducer.State) {
        canShowRegionSelection = state.canShowRegionOnboarding
        groups = state.groups
        showsVideoOnboarding = state.canShowVideoOnboarding
        video = state.video
      }
    }

    viewStore.publisher
      .map(Items.init)
      .removeDuplicates()
      .dropFirst(1)
      .sink { [weak self] _ in
        self?.performUpdates()
      }
      .store(in: &cancellables)

    viewStore.publisher.isUpdating
      .sink { [weak self] isLoading in
        if !isLoading {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self?.refreshControl.endRefreshing()
          }
        }
      }
      .store(in: &cancellables)

    viewStore.publisher.regions
      .sink { [weak self] regions in
        if let regions {
          self?.presentRegionOnboarding(with: regions)
        } else {
          self?.dismissRegionOnboarding()
        }
      }
      .store(in: &cancellables)

    store.scope(state: \.article, action: TodayReducer.Action.article)
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

  func scrollToTop() {
    var point = CGPoint.zero
    point.y -= node.view.adjustedContentInset.top
    point.x -= node.view.adjustedContentInset.left
    node.setContentOffset(point, animated: true)
  }

  @objc private func didRefresh() {
    viewStore.send(.refreshTriggered)
  }

  private func performUpdates() {
    adapter.performUpdates(animated: viewStore.areAnimationsEnabled)
  }

  private func presentRegionOnboarding(with regions: [Feed]) {
    let regionViewController = RegionViewController(
      configuration: .init(feeds: regions)
    )
    self.regionViewController = regionViewController
    regionViewController.onConfirmTap = { [weak self, weak regionViewController] in
      if let region = regionViewController?.configuration.selectedFeed {
        self?.viewStore.send(.regionOnboardingFeedSelected(region))
      }
    }
    regionViewController.onDismissTap = { [weak self, weak regionViewController] in
      regionViewController?.dismiss(animated: true) {
        self?.viewStore.send(.closeRegionOnboardingTapped)
      }
    }

    let navigationController = UINavigationController(rootViewController: regionViewController)
    navigationController.presentationController?.delegate = self
    present(navigationController, animated: true)
  }

  private func dismissRegionOnboarding() {
    regionViewController?.dismiss(animated: true)
  }

  private func presentVideo(_ video: Video) {
    let videoViewController = VideoViewController(video: video)
    videoViewController.onDidPlayToEndTime = { [weak videoViewController] in
      videoViewController?.dismiss(animated: true)
    }
    videoViewController.onDismiss = { [weak self] in
      self?.viewStore.send(.videoDismissed)
    }
    present(videoViewController, animated: true)
  }
}

extension TodayViewController: ListAdapterDataSource {
  func listAdapter(_: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
    if let configuration = ArticlesSectionConfiguration(diffable: object) {
      let controller = ArticlesSectionController()
      controller.onArticleSelected = { [weak self] article in
        self?.viewStore.send(.articleSelected(article))
      }
      controller.stylingBlock = configuration.title == nil
        ? TodayViewController.homeStyling
        : TodayViewController.sectionStyling
      return controller
    }

    if VideoSectionConfiguration(diffable: object) != nil {
      let controller = VideoSectionController()
      controller.onVideoTap = { [weak self] video in
        self?.presentVideo(video)
      }
      return controller
    }

    if let configuration = TodayOnboardingConfiguration(diffable: object) {
      let controller = TodayOnboardingSectionController()
      controller.onConfirmTap = { [weak self] in
        switch configuration.identifier {
        case TodayOnboardingConfiguration.region.identifier:
          self?.viewStore.send(.startRegionOnboardingTapped)
        case TodayOnboardingConfiguration.video.identifier:
          self?.viewStore.send(.enableVideoNotificationsTapped)
        default:
          break
        }
      }
      controller.onDismissTap = { [weak self] in
        switch configuration.identifier {
        case TodayOnboardingConfiguration.region.identifier:
          self?.viewStore.send(.ignoreRegionOnboardingTapped)
        case TodayOnboardingConfiguration.video.identifier:
          self?.viewStore.send(.videoOnboardingCompleted)
        default:
          break
        }
      }
      return controller
    }

    if HeadlinesSectionConfiguration(diffable: object) != nil {
      let controller = HeadlinesSectionController()
      controller.onArticleSelected = { [weak self] article in
        self?.viewStore.send(.articleSelected(article))
      }
      return controller
    }

    return ThatsAllSectionController()
  }

  func objects(for _: ListAdapter) -> [ListDiffable] {
    var objects = [] as [ListDiffable]

    let groups = viewStore.groups
    guard groups.home != nil else {
      return objects
    }

    if let video = viewStore.video {
      objects.append(
        VideoSectionConfiguration(
          video: video
        ).diffable()
      )
    }

    if let home = groups.home {
      objects.append(
        ArticlesSectionConfiguration(
          identifier: "com.mttcrsp.ansia.today.home",
          articles: home.articles
        ).diffable()
      )
    }

    if let region = groups.region, let feed = region.feed, !region.articles.isEmpty {
      objects.append(
        HeadlinesSectionConfiguration(
          identifier: feed.slug.rawValue,
          title: feed.title,
          articles: region.articles
        ).diffable()
      )
    } else if groups.region == nil, viewStore.canShowRegionOnboarding {
      objects.append(TodayOnboardingConfiguration.region.diffable())
    }

    if viewStore.canShowVideoOnboarding, !viewStore.canShowRegionOnboarding {
      objects.append(TodayOnboardingConfiguration.video.diffable())
    }

    for section in groups.sections.sorted(by: { lhs, rhs in (lhs.feed?.weight ?? 0) < (rhs.feed?.weight ?? 0) }) {
      if let feed = section.feed {
        objects.append(
          ArticlesSectionConfiguration(
            identifier: feed.slug.rawValue,
            title: feed.title,
            articles: section.articles
          ).diffable()
        )
      }
    }

    objects.append(ThatsAllSectionConfiguration().diffable())
    return objects
  }

  func emptyView(for _: ListAdapter) -> UIView? {
    nil
  }
}

extension TodayViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_: UIPresentationController) {
    viewStore.send(.closeRegionOnboardingTapped)
  }
}

private extension TodayViewController {
  static let homeStyling: ArticlesSectionController.StylingBlock = { element in
    if element.index == 0 {
      return .fullWidth
    } else if element.article.description == nil {
      return .text
    } else if let description = element.article.description, description.count > 60, element.article.title.count > 60 {
      return .largeText
    } else {
      return .default
    }
  }

  static let sectionStyling: ArticlesSectionController.StylingBlock = { element in
    element.index == 0 ? .large : .default
  }
}

private extension TodayOnboardingConfiguration {
  static let region = TodayOnboardingConfiguration(
    identifier: "com.mttcrsp.ansia.today.regionOnboarding",
    title: L10n.RegionOnboarding.title,
    message: L10n.RegionOnboarding.message,
    confirm: L10n.RegionOnboarding.confirm,
    dismiss: L10n.RegionOnboarding.dismiss
  )

  static let video = TodayOnboardingConfiguration(
    identifier: "com.mttcrsp.ansia.today.videoOnboarding",
    title: L10n.VideoOnboarding.title,
    message: L10n.VideoOnboarding.message,
    confirm: L10n.VideoOnboarding.confirm,
    dismiss: L10n.VideoOnboarding.dismiss
  )
}
