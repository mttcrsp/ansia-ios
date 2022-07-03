import AsyncDisplayKit

public final class ActionableNode: ASDisplayNode {
  public var preferredLayoutMargins: UIEdgeInsets {
    let bottom = bottomNode.frame.height + containerNode.frame.height
    return .init(top: 0, left: 0, bottom: bottom, right: 0)
  }

  private let bottomNode: ASDisplayNode
  private let containerNode: ASDisplayNode

  public init(contentNode: ASDisplayNode, actionsNode: ASDisplayNode) {
    let backgroundColor = DesignSystemAsset.background.color

    let bottomNode = ASDisplayNode()
    bottomNode.backgroundColor = backgroundColor
    self.bottomNode = bottomNode

    let containerNode = ASDisplayNode()
    containerNode.backgroundColor = backgroundColor
    self.containerNode = containerNode

    let topNode = ASDisplayNode(layerBlock: {
      let layer = CAGradientLayer()
      layer.colors = [
        backgroundColor.withAlphaComponent(0).cgColor,
        backgroundColor.cgColor,
      ]
      layer.startPoint = .init(x: 0.5, y: 0)
      layer.endPoint = .init(x: 0.5, y: 0.9)
      return layer
    })

    super.init()

    automaticallyManagesSubnodes = true
    automaticallyRelayoutOnLayoutMarginsChanges = true
    layoutSpecBlock = { node, _ in
      ASOverlayLayoutSpec(
        child: contentNode,
        overlay: ASRelativeLayoutSpec(
          horizontalPosition: .none,
          verticalPosition: .end,
          sizingOption: .minimumHeight,
          child: ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .center,
            alignItems: .stretch,
            children: [
              topNode.styled { style in
                style.height = .init(unit: .points, value: 16)
              },
              ASBackgroundLayoutSpec(
                child: ASInsetLayoutSpec(
                  insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16),
                  child: actionsNode
                ),
                background: containerNode
              ),
              bottomNode.styled { style in
                style.height = .init(unit: .points, value: node.layoutMargins.bottom)
              },
            ]
          )
        )
      )
    }
  }
}
