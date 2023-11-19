import AsyncDisplayKit

public final class ArticleNode: ASDisplayNode {
  public struct Configuration: Hashable {
    public enum Style {
      case `default`, fullWidth, large, small, largeText, text
    }

    public let description: String?
    public let imageURL: URL?
    public let publishedAt: Date
    public let style: Style
    public let title: String
    public init(description: String? = nil, imageURL: URL? = nil, publishedAt: Date, style: ArticleNode.Configuration.Style, title: String) {
      self.description = description
      self.imageURL = imageURL
      self.publishedAt = publishedAt
      self.style = style
      self.title = title
    }
  }

  private lazy var titleNode: ASTextNode = {
    let node = ASTextNode()
    node.attributedText = NSAttributedString(
      string: configuration.title,
      attributes: titleAttributes
    )
    return node
  }()

  private lazy var descriptionNode: ASTextNode = {
    let node = ASTextNode()
    node.attributedText = NSAttributedString(
      string: configuration.description ?? "",
      attributes: [
        .foregroundColor: DesignSystemAsset.secondaryLabel.color,
        .font: FontFamily.NYTImperial.regular.font(size: 16),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 22
          paragraphStyle.minimumLineHeight = 22
          return paragraphStyle
        }(),
      ]
    )
    return node
  }()

  private lazy var publishedAtNode = PublishedAtNode(
    configuration: .init(publishedAt: configuration.publishedAt)
  )

  private let imageZoom = ZoomBehavior()

  private lazy var imageBackgroundNode: ASDisplayNode = {
    let node = ASDisplayNode()
    node.backgroundColor = .quaternarySystemFill
    return node
  }()

  private lazy var imageNode: ASNetworkImageNode = {
    let node = ASNetworkImageNode()
    node.backgroundColor = .quaternarySystemFill
    node.delegate = self
    node.isHidden = true
    node.url = configuration.imageURL
    return node
  }()

  public let configuration: Configuration

  public init(configuration: Configuration) {
    self.configuration = configuration
    super.init()
    automaticallyManagesSubnodes = true
  }
}

extension ArticleNode {
  override public func layoutSpecThatFits(_ range: ASSizeRange) -> ASLayoutSpec {
    switch configuration.style {
    case .default:
      return defaultSpecThatFits(range)
    case .fullWidth:
      return fullWidthSpecThatFits(range)
    case .large:
      return largeSpecThatFits(range)
    case .largeText:
      return largeTextSpecThatFits(range)
    case .small:
      return smallSpecThatFits(range)
    case .text:
      return textSpecThatFits(range)
    }
  }

  private func defaultSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 12,
      justifyContent: .spaceBetween,
      alignItems: .start,
      children: [
        ASStackLayoutSpec(
          direction: .vertical,
          spacing: 8,
          justifyContent: .start,
          alignItems: .start,
          children: [titleNode, descriptionNode, publishedAtNode]
        ).styled { style in
          style.flexShrink = 1
        },
        ASRatioLayoutSpec(
          ratio: imageAspectRatio,
          child: imageNode
        ).styled { style in
          style.preferredLayoutSize.height = .init(unit: .points, value: 95)
        },
      ]
    )
  }

  private func fullWidthSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .start,
      alignItems: .start,
      children: [
        ASBackgroundLayoutSpec(
          child: ASRatioLayoutSpec(
            ratio: imageAspectRatio,
            child: imageNode
          ),
          background: imageBackgroundNode
        ),
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16),
          child: ASStackLayoutSpec(
            direction: .vertical,
            spacing: 12,
            justifyContent: .start,
            alignItems: .start,
            children: [titleNode, descriptionNode, publishedAtNode]
          )
        ),
      ]
    )
  }

  private func largeSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .vertical,
      spacing: 8,
      justifyContent: .start,
      alignItems: .start,
      children: [
        ASRatioLayoutSpec(
          ratio: imageAspectRatio,
          child: imageNode.styled { style in
            style.preferredLayoutSize.height = .init(unit: .points, value: 140)
          }
        ).styled { style in
          style.spacingBefore = 16
        },
        titleNode,
        descriptionNode,
        publishedAtNode,
      ]
    )
  }

  private func smallSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 16,
      justifyContent: .spaceBetween,
      alignItems: .center,
      children: [
        ASRatioLayoutSpec(
          ratio: imageAspectRatio,
          child: imageNode
        ).styled { style in
          style.preferredLayoutSize.height = .init(unit: .points, value: 72)
        },
        ASStackLayoutSpec(
          direction: .vertical,
          spacing: 6,
          justifyContent: .start,
          alignItems: .start,
          children: [titleNode]
        ).styled { style in
          style.flexShrink = 1
        },
      ]
    )
  }

  private func largeTextSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .vertical,
      spacing: 8,
      justifyContent: .start,
      alignItems: .start,
      children: [titleNode, descriptionNode, publishedAtNode]
    )
  }

  private func textSpecThatFits(_: ASSizeRange) -> ASLayoutSpec {
    ASStackLayoutSpec(
      direction: .vertical,
      spacing: 8,
      justifyContent: .start,
      alignItems: .start,
      children: [titleNode, publishedAtNode]
    )
  }

  private var imageAspectRatio: CGFloat {
    switch configuration.style {
    case .fullWidth, .large:
      return 2 / 3
    case .default, .small:
      return 1
    case .largeText, .text: // image not displayed
      return 1
    }
  }

  private var titleAttributes: [NSAttributedString.Key: Any] {
    switch configuration.style {
    case .fullWidth, .large:
      return [
        .foregroundColor: DesignSystemAsset.label.color,
        .font: FontFamily.NYTCheltenham.bold.font(size: 32),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 36
          paragraphStyle.minimumLineHeight = 36
          return paragraphStyle
        }(),
      ]
    case .largeText, .default, .small, .text:
      return [
        .foregroundColor: DesignSystemAsset.label.color,
        .font: FontFamily.NYTCheltenham.bold.font(size: 20),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 23
          paragraphStyle.minimumLineHeight = 23
          return paragraphStyle
        }(),
        .kern: 0.2,
      ]
    }
  }
}

extension ArticleNode: ASNetworkImageNodeDelegate {
  public func imageNode(_ imageNode: ASNetworkImageNode, didLoad image: UIImage) {
    DispatchQueue.global().async { [weak self] in
      if let self, let cgImage = image.cgImage {
        FacesDetectionClient().perform(
          FacesDetectionClient.Request(cgImage: cgImage, ratio: imageAspectRatio)
        ) { [weak imageNode] smartCroppingRect in
          if let imageNode, let smartCroppingRect {
            DispatchQueue.main.async {
              imageNode.isHidden = false
              imageNode.cropRect.origin = smartCroppingRect.origin
            }
          } else {
            imageNode?.isHidden = false
          }
        }
      }
    }
  }
}
