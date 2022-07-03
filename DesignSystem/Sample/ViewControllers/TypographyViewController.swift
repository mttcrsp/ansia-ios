import AsyncDisplayKit
import DesignSystem

final class TypographyViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    super.init(node: .init())

    let fonts: [UIFont] = [
      FontFamily.NYTCheltenham.extraBoldItal.font(size: 34),
      FontFamily.NYTCheltenham.medium.font(size: 21),
      FontFamily.NYTImperial.regular.font(size: 18),
      FontFamily.NYTFranklin.headline.font(size: 11),
    ]
    let fontsNodes = fonts.map { font in
      let node = ASTextNode()
      node.attributedText = .init(
        string: "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
        attributes: [.font: font, .foregroundColor: DesignSystemAsset.label.color]
      )
      return node
    }

    var children: [ASDisplayNode] = []
    for (index, node) in fontsNodes.enumerated() {
      if index != 0 {
        children.append(SeparatorNode())
      }
      children.append(node)
    }

    node.automaticallyManagesSubnodes = true
    node.automaticallyRelayoutOnLayoutMarginsChanges = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { node, _ in
      ASInsetLayoutSpec(
        insets: node.layoutMargins,
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 16,
          justifyContent: .center,
          alignItems: .center,
          children: children.map { node in
            node.styled { style in
              style.width = .init(unit: .fraction, value: 1)
            }
          }
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func buttonTapped() {
    print(#function, Date())
  }
}
