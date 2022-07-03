import AsyncDisplayKit
import Core
import DesignSystem
import IGListSwiftKit

struct VideoSectionConfiguration: ListIdentifiable {
  let video: Video
  var diffIdentifier: NSObjectProtocol {
    video.videoID.rawValue as NSString
  }
}

final class VideoSectionController: ListValueSectionController<VideoSectionConfiguration> {
  override init() {
    super.init()
    inset.bottom = 16
  }

  var onVideoTap: (Video) -> Void = { _ in }
  override func didSelectItem(at _: Int) {
    onVideoTap(value.video)
  }

  func nodeBlockForItem(at _: Int) -> ASCellNodeBlock {
    let video = value.video
    return {
      let videoNode = VideoNode(video: video)
      let node = CellNode()
      node.automaticallyManagesSubnodes = true
      node.style.preferredLayoutSize.width = .init(unit: .fraction, value: 1)
      node.layoutSpecBlock = { _, _ in
        ASWrapperLayoutSpec(layoutElement: videoNode)
      }
      return node
    }
  }
}

extension VideoSectionController: ASSectionController {
  override func sizeForItem(at index: Int) -> CGSize {
    ASIGListSectionControllerMethods.sizeForItem(at: index)
  }

  override func cellForItem(at index: Int) -> UICollectionViewCell {
    ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
  }
}

private final class VideoNode: ASDisplayNode {
  private let video: Video

  init(video: Video) {
    self.video = video

    let liveBackgroundNode = ASDisplayNode()
    liveBackgroundNode.backgroundColor = .white
    liveBackgroundNode.cornerRadius = 4

    let liveNode = ASTextNode()
    liveNode.attributedText = NSAttributedString(
      string: L10n.Today.watchNow.uppercased(),
      attributes: [
        .foregroundColor: DesignSystemAsset.fill.color,
        .font: FontFamily.NYTFranklin.bold.font(size: 12),
        .kern: 0.48,
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 14
          paragraphStyle.minimumLineHeight = 14
          return paragraphStyle
        }(),
      ]
    )

    let dotHeight: CGFloat = 4
    let dotNode = ASDisplayNode()
    dotNode.backgroundColor = .white
    dotNode.cornerRadius = dotHeight / 2

    let textNode = ASTextNode()
    textNode.attributedText = NSAttributedString(
      string: "•  " + video.title,
      attributes: [
        .font: FontFamily.NYTFranklin.bold.font(size: 16),
        .foregroundColor: UIColor.white,
      ]
    )

    super.init()

    automaticallyManagesSubnodes = true
    backgroundColor = DesignSystemAsset.fill.color
    layoutSpecBlock = { _, _ in
      ASInsetLayoutSpec(
        insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
        child: ASStackLayoutSpec(
          direction: .horizontal,
          spacing: 10,
          justifyContent: .spaceBetween,
          alignItems: .center,
          children: [
            textNode,
            ASBackgroundLayoutSpec(
              child: ASInsetLayoutSpec(
                insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8),
                child: liveNode
              ),
              background: liveBackgroundNode
            ),
          ]
        )
      )
    }
  }
}
