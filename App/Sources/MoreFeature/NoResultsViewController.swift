import AsyncDisplayKit
import DesignSystem

final class NoResultsViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    let textNode = ASTextNode()
    textNode.attributedText = .init(
      string: "Nessun risultato",
      attributes: [
        .foregroundColor: DesignSystemAsset.tertiaryLabel.color,
        .font: FontFamily.NYTCheltenham.mediumItalic.font(size: 21),
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 27
          paragraphStyle.minimumLineHeight = 27
          return paragraphStyle
        }(),
      ]
    )

    super.init(node: .init())
    node.accessibilityIdentifier = "no_results"
    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASCenterLayoutSpec(
          horizontalPosition: .center,
          verticalPosition: .center,
          sizingOption: .minimumSize,
          child: textNode
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
