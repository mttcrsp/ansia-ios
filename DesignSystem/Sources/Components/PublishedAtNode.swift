import AsyncDisplayKit

public final class PublishedAtNode: ASTextNode {
  public struct Configuration {
    public let publishedAt: Date
    public init(publishedAt: Date) {
      self.publishedAt = publishedAt
    }
  }

  private var timer: Timer?

  public let configuration: Configuration

  public init(configuration: Configuration) {
    self.configuration = configuration
    super.init()
  }

  deinit {
    timer?.invalidate()
    timer = nil
  }

  override public func didEnterVisibleState() {
    super.didEnterVisibleState()
    attributedText = publishedAtString
    timer = .scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      self?.attributedText = self?.publishedAtString
    }
  }

  override public func didExitVisibleState() {
    super.didExitVisibleState()
    timer?.invalidate()
    timer = nil
  }

  private static let publishedAtFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = .italian
    return formatter
  }()

  private var publishedAtString: NSAttributedString? {
    let elapsed = Self.publishedAtFormatter
      .localizedString(for: configuration.publishedAt, relativeTo: Date())
      .uppercased(with: .autoupdatingCurrent)

    let isRecent = Locale.italian.calendar.isRecent(configuration.publishedAt)
    let attributedString = NSMutableAttributedString()
    let attributedStringColor = isRecent
      ? DesignSystemAsset.live.color
      : DesignSystemAsset.secondaryLabel.color

    if isRecent {
      attributedString.append(
        .init(
          string: "\(DesignSystemL10n.Published.live) ",
          attributes: [
            .foregroundColor: attributedStringColor,
            .font: FontFamily.NYTFranklin.headline.font(size: 11),
            .kern: 1.1,
            .paragraphStyle: {
              let paragraphStyle = NSMutableParagraphStyle()
              paragraphStyle.maximumLineHeight = 14
              paragraphStyle.minimumLineHeight = 14
              return paragraphStyle
            }(),
          ]
        )
      )
    }

    attributedString.append(
      .init(
        string: elapsed,
        attributes: [
          .foregroundColor: attributedStringColor,
          .font: FontFamily.NYTFranklin.medium.font(size: 11),
          .kern: 1.1,
          .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 14
            paragraphStyle.minimumLineHeight = 14
            return paragraphStyle
          }(),
        ]
      )
    )

    return attributedString
  }
}
