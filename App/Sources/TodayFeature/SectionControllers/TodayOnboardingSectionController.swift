import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct TodayOnboardingConfiguration: Hashable, ListIdentifiable {
  let identifier: String
  let title: String
  let message: String
  let confirm: String
  let dismiss: String
  var diffIdentifier: NSObjectProtocol {
    identifier as NSString
  }
}

final class TodayOnboardingSectionController: ListValueSectionController<TodayOnboardingConfiguration> {
  var onConfirmTap: () -> Void = {}
  var onDismissTap: () -> Void = {}

  @objc private func didTapConfirm() {
    onConfirmTap()
  }

  @objc private func didTapDismiss() {
    onDismissTap()
  }

  override func numberOfItems() -> Int {
    1
  }

  func nodeBlockForItem(at _: Int) -> ASCellNodeBlock {
    let value: TodayOnboardingConfiguration = value
    return {
      let titleNode = ASTextNode()
      titleNode.attributedText = NSAttributedString(
        string: value.title,
        attributes: [
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
      )

      let detailNode = ASTextNode()
      detailNode.attributedText = NSAttributedString(
        string: value.message,
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

      let dismissAction = #selector(TodayOnboardingSectionController.didTapDismiss)
      let dismissNode = ButtonNode(configuration: .secondary)
      dismissNode.addTarget(self, action: dismissAction, forControlEvents: .touchUpInside)
      dismissNode.setTitle(value.dismiss, for: .normal)

      let confirmAction = #selector(TodayOnboardingSectionController.didTapConfirm)
      let confirmNode = ButtonNode(configuration: .primary)
      confirmNode.addTarget(self, action: confirmAction, forControlEvents: .touchUpInside)
      confirmNode.setTitle(value.confirm, for: .normal)

      let node = ASCellNode()
      node.automaticallyManagesSubnodes = true
      node.style.width = .init(unit: .fraction, value: 1)
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16),
          child: ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .stretch,
            children: [
              titleNode.styled { style in
                style.spacingAfter = 8
              },
              detailNode.styled { style in
                style.spacingAfter = 16
              },
              ASStackLayoutSpec(
                direction: .horizontal,
                spacing: 16,
                justifyContent: .start,
                alignItems: .center,
                children: [dismissNode, confirmNode].map { node in
                  node.styled { style in
                    style.flexGrow = 1
                    style.flexBasis = .init(unit: .points, value: 0)
                  }
                }
              ).styled { style in
                style.spacingAfter = 20
              },
              SeparatorNode(configuration: .prominent),
            ]
          )
        )
      }
      return node
    }
  }
}

extension TodayOnboardingSectionController: ListSupplementaryViewSource, ASSupplementaryNodeSource {
  func supportedElementKinds() -> [String] {
    [UICollectionView.elementKindSectionFooter]
  }

  func nodeBlockForSupplementaryElement(ofKind _: String, at _: Int) -> ASCellNodeBlock {
    {
      let separatorNode = SeparatorNode(configuration: .prominent)
      let node = ASCellNode()
      node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
      node.automaticallyManagesSubnodes = true
      node.layoutSpecBlock = { _, _ in
        ASInsetLayoutSpec(
          insets: UIEdgeInsets(top: 24, left: 16, bottom: 16, right: 16),
          child: separatorNode
        )
      }
      return node
    }
  }
}

extension TodayOnboardingSectionController: ASSectionController {
  override func sizeForItem(at index: Int) -> CGSize {
    ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }

  func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
    ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryView(ofKind: elementKind, at: index)
  }

  func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    ASIGListSupplementaryViewSourceMethods.viewForSupplementaryElement(ofKind: elementKind, at: index, sectionController: self)
  }

  func sizeRangeForSupplementaryElement(ofKind elementKind: String, at _: Int) -> ASSizeRange {
    supportedElementKinds().contains(elementKind) ? ASSizeRangeUnconstrained : ASSizeRangeZero
  }
}
