import AsyncDisplayKit

public final class DisclosureButtonNode: ASButtonNode {
  public struct Configuration {
    public let title: String
    public init(title: String) {
      self.title = title
    }
  }

  override public var isHighlighted: Bool {
    didSet { didChangeHighlighting() }
  }

  public var onTap: () -> Void = {}

  public init(configuration: Configuration) {
    super.init()
    addTarget(self, action: #selector(didTap), forControlEvents: .touchUpInside)

    let font = FontFamily.NYTFranklin.semibold.font(size: 12)

    let title = NSMutableAttributedString()
    title.append(
      .init(
        string: "\(configuration.title) "
          .uppercased(with: Locale.italian),
        attributes: [
          .font: font,
          .foregroundColor: DesignSystemAsset.label.color,
          .kern: 0.8,
        ]
      )
    )

    if let image = UIImage(systemName: "chevron.right") {
      title.append(
        .init(
          attachment: .init(
            image: image.withConfiguration(UIImage.SymbolConfiguration(font: font))
          )
        )
      )
    }

    setAttributedTitle(title, for: .normal)
  }

  private func didChangeHighlighting() {
    alpha = isHighlighted ? 0.5 : 1
  }

  @objc private func didTap() {
    onTap()
  }
}
