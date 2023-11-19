import AsyncDisplayKit
import Combine
import ComposableArchitecture
import Core
import DesignSystem

class ArticleViewController: ASDKViewController<ASScrollNode> {
  private let imageZoom = ZoomBehavior()
  private let viewStore: ViewStoreOf<ArticleReducer>
  private var bookmarkItem: UIBarButtonItem?
  private var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<ArticleReducer>) {
    viewStore = ViewStore(store, observe: { $0 })

    super.init(node: .init())

    bookmarkItem = UIBarButtonItem(
      image: UIImage(systemName: viewStore.showsBookmark ? "bookmark.fill" : "bookmark"),
      primaryAction: .init { [weak self] _ in
        self?.viewStore.send(.bookmarkStatusToggled)
      }
    )
    bookmarkItem?.accessibilityIdentifier = "bookmark_button"

    navigationItem.rightBarButtonItem = bookmarkItem
    navigationItem.standardAppearance = .opaque
    hidesBottomBarWhenPushed = true

    let imageBackgroundNode = ASDisplayNode()
    imageBackgroundNode.backgroundColor = .quaternarySystemFill

    let imageNode = ASNetworkImageNode()
    imageNode.contentMode = .scaleAspectFill
    imageNode.delegate = self
    imageNode.url = viewStore.article.imageURL
    imageNode.imageModificationBlock

    let titleNode = ASTextNode()
    titleNode.attributedText = NSAttributedString(
      string: viewStore.article.title,
      attributes: [
        .foregroundColor: DesignSystemAsset.label.color,
        .font: FontFamily.NYTCheltenham.extraBoldItal.font(size: 34),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 39
          paragraphStyle.minimumLineHeight = 39
          return paragraphStyle
        }(),
      ]
    )

    var descriptionNode: ASTextNode?
    if let string = viewStore.article.description, !string.isEmpty {
      descriptionNode = ASTextNode()
      descriptionNode?.attributedText = NSAttributedString(
        string: string,
        attributes: [
          .foregroundColor: DesignSystemAsset.label.color,
          .font: FontFamily.NYTCheltenham.medium.font(size: 21),
          .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 27
            paragraphStyle.minimumLineHeight = 27
            return paragraphStyle
          }(),
        ]
      )
    }

    let contentNode = ASTextNode()
    contentNode.accessibilityIdentifier = "content_label"
    contentNode.attributedText = NSAttributedString(
      string: viewStore.article.content,
      attributes: [
        .foregroundColor: DesignSystemAsset.secondaryLabel.color,
        .font: FontFamily.NYTImperial.regular.font(size: 18),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 26
          paragraphStyle.minimumLineHeight = 26
          paragraphStyle.paragraphSpacing = 12
          return paragraphStyle
        }(),
      ]
    )

    let publishedAtNode = PublishedAtNode(
      configuration: .init(publishedAt: viewStore.article.publishedAt)
    )
    publishedAtNode.accessibilityIdentifier = "published_label"

    let shareNode = ButtonNode(configuration: .primary)
    shareNode.setTitle("Condividi", for: .normal)
    shareNode.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
    shareNode.addTarget(self, action: #selector(didTapShare), forControlEvents: .touchUpInside)

    node.automaticallyManagesContentSize = true
    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: UIEdgeInsets(top: node.layoutMargins.top, left: 0, bottom: node.layoutMargins.bottom, right: 0),
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 16,
          justifyContent: .start,
          alignItems: .start,
          children: [
            ASRatioLayoutSpec(
              ratio: 2 / 3,
              child: ASBackgroundLayoutSpec(
                child: imageNode,
                background: imageBackgroundNode
              )
            ),
            ASInsetLayoutSpec(
              insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16),
              child: ASStackLayoutSpec(
                direction: .vertical,
                spacing: 16,
                justifyContent: .start,
                alignItems: .start,
                children: [
                  publishedAtNode,
                  titleNode,
                  descriptionNode,
                  contentNode,
                  shareNode.styled { style in
                    style.alignSelf = .center
                    style.spacingAfter = 32
                    style.spacingBefore = 32
                  },
                ].compactMap { $0 }
              )
            ),
          ]
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    node.view.contentInsetAdjustmentBehavior = .never

    viewStore.publisher
      .sink { [weak self] state in
        self?.bookmarkItem?.image = UIImage(
          systemName: state.showsBookmark ? "bookmark.fill" : "bookmark"
        )
      }
      .store(in: &cancellables)

    viewStore.send(.didLoad)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewStore.send(.didAppear)
  }

  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    if parent == nil {
      viewStore.send(.didUnload)
    }
  }

  @objc private func didTapShare() {
    let shareViewController = UIActivityViewController(activityItems: [viewStore.article.url], applicationActivities: nil)
    present(shareViewController, animated: true)
  }
}

extension ArticleViewController: ASNetworkImageNodeDelegate {
  func imageNode(_ imageNode: ASNetworkImageNode, didLoad _: UIImage) {
    imageZoom.attach(to: imageNode.view)
  }
}
