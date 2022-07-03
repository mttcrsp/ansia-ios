import AsyncDisplayKit

public final class HeaderNode: ASTextNode {
  public struct Configuration {
    public enum Style {
      case `default`, large
    }

    public let style: Style
    public let title: String
    public let uppercased: Bool
    public init(title: String, uppercased: Bool = true, style: Style = .default) {
      self.style = style
      self.title = title
      self.uppercased = uppercased
    }
  }

  public init(configuration: Configuration) {
    super.init()

    let string = configuration.uppercased
      ? configuration.title.uppercased(with: .autoupdatingCurrent)
      : configuration.title

    attributedText = NSAttributedString(
      string: string,
      attributes: configuration.style.attributes
    )
  }
}

private extension HeaderNode.Configuration.Style {
  var attributes: [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any]
    switch self {
    case .default:
      attributes = [
        .font: FontFamily.NYTFranklin.bold.font(size: 16),
        .kern: 0.5,
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 18
          paragraphStyle.minimumLineHeight = 18
          return paragraphStyle
        }(),
      ]
    case .large:
      attributes = [
        .font: FontFamily.NYTFranklin.bold.font(size: 18),
        .kern: 0.6,
        .paragraphStyle: {
          let paragraphStyle = NSMutableParagraphStyle()
          paragraphStyle.maximumLineHeight = 20
          paragraphStyle.minimumLineHeight = 20
          return paragraphStyle
        }(),
      ]
    }

    attributes[.foregroundColor] = DesignSystemAsset.label.color
    return attributes
  }
}
