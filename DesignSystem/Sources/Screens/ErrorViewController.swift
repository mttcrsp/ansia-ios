import AsyncDisplayKit

public final class ErrorViewController: ASDKViewController<ASDisplayNode> {
  public struct Configuration {
    public let title: String
    public let message: String
    public let action: String
    public init(title: String, message: String, action: String) {
      self.title = title
      self.message = message
      self.action = action
    }
  }

  public var onActionTap: () -> Void = {}

  public init(configuration: Configuration = .default) {
    super.init(node: .init())

    let titleNode = ASTextNode()
    titleNode.attributedText = NSAttributedString(
      string: configuration.title,
      attributes: [
        .foregroundColor: DesignSystemAsset.label.color,
        .font: FontFamily.NYTCheltenham.bold.font(size: 32),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 36
          paragraphStyle.minimumLineHeight = 36
          return paragraphStyle
        }(),
      ]
    )

    let messageNode = ASTextNode()
    messageNode.attributedText = NSAttributedString(
      string: configuration.message,
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

    let actionNode = ButtonNode(configuration: .primary)
    actionNode.setTitle(configuration.action, for: .normal)
    actionNode.addTarget(self, action: #selector(didTapAction), forControlEvents: .touchUpInside)

    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 16,
          justifyContent: .spaceBetween,
          alignItems: .center,
          children: [
            ASStackLayoutSpec(
              direction: .vertical,
              spacing: 8,
              justifyContent: .center,
              alignItems: .center,
              children: [titleNode, messageNode]
            ).styled { style in
              style.flexGrow = 1
            },
            actionNode.styled { style in
              style.width = .init(unit: .fraction, value: 1)
            },
          ]
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func didTapAction() {
    onActionTap()
  }
}

public extension ErrorViewController.Configuration {
  static let `default` = Self(
    title: "Whoops",
    message: "Something went wrong",
    action: "Retry"
  )
}
