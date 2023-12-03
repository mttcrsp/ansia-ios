import UIKit

public final class PublishedAtFormatter {
  private static let formatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = .italian
    return formatter
  }()

  public init() {}
  public func attributedString(for date: Date) -> NSAttributedString {
    let elapsed = Self.formatter
      .localizedString(for: date, relativeTo: Date())
      .uppercased(with: .autoupdatingCurrent)

    let isRecent = Locale.italian.calendar.isRecent(date)
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
