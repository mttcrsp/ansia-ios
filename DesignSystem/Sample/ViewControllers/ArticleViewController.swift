import AsyncDisplayKit
import DesignSystem

final class ArticleViewController: ASDKViewController<ASScrollNode> {
  override init() {
    super.init(node: .init())

    let articleStyles: [ArticleNode.Configuration.Style] = [.fullWidth, .large, .default, .small]
    let articleNodes = articleStyles.map { style in
      ArticleNode(configuration: .init(
        description: "'Se Apple e Android tolgono Twitter dai loro app store'",
        imageURL: URL(string: "https://www.ansia.it/webimages/img_700/2022/11/24/c6b3ab0459a6e9a4433ad5cd9512210e.jpg"),
        publishedAt: Date().addingTimeInterval(-3600),
        style: style,
        title: "Nuova provocazione di Elon Musk, potrei creare il mio smartphone"
      ))
    }

    var children: [ASDisplayNode] = []
    for (index, articleNode) in articleNodes.enumerated() {
      if index != 0 {
        children.append(SeparatorNode())
      }
      children.append(articleNode)
    }

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
          justifyContent: .center,
          alignItems: .center,
          children: children
            .map { node in
              var insets = UIEdgeInsets.zero
              if node is SeparatorNode {
                insets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
              } else if let node = node as? ArticleNode, node.configuration.style != .fullWidth {
                insets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
              }
              return ASInsetLayoutSpec(insets: insets, child: node)
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
