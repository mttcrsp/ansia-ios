import AsyncDisplayKit

public final class ButtonNode: ASButtonNode {
  public struct Configuration {
    public let textColor: UIColor
    public let borderColor: UIColor
    public let backgroundColor: UIColor
    public let disabledBackgroundColor: UIColor
    public let highlightedBackgroundColor: UIColor

    public init(textColor: UIColor, borderColor: UIColor, backgroundColor: UIColor, disabledBackgroundColor: UIColor, highlightedBackgroundColor: UIColor) {
      self.textColor = textColor
      self.borderColor = borderColor
      self.backgroundColor = backgroundColor
      self.disabledBackgroundColor = disabledBackgroundColor
      self.highlightedBackgroundColor = highlightedBackgroundColor
    }
  }

  private let configuration: ButtonNode.Configuration
  private let font = FontFamily.NYTFranklin.semibold.font(size: 16)

  public init(configuration: ButtonNode.Configuration) {
    self.configuration = configuration
    super.init()

    contentEdgeInsets = .init(top: 12, left: 16, bottom: 12, right: 16)

    for state in [.normal, .disabled, .highlighted] as [UIControl.State] {
      setBackgroundImage(.as_resizableRoundedImage(
        withCornerRadius: 3,
        cornerColor: .clear,
        fill: configuration.fillColor(for: state),
        borderColor: configuration.borderColor(for: state),
        borderWidth: 1,
        traitCollection: primitiveTraitCollection()
      ), for: state)
    }
  }

  public func setTitle(_ title: String, for state: UIControl.State) {
    super.setTitle(title, with: font, with: configuration.textColor, for: state)
    super.setTitle(title, with: font, with: configuration.textColor.disabled, for: .disabled)
  }

  override public func setImage(_ image: UIImage?, for _: UIControl.State) {
    let adjustedImage = image?
      .withTintColor(configuration.textColor, renderingMode: .alwaysTemplate)
      .withConfiguration(UIImage.SymbolConfiguration(font: font))
    super.setImage(adjustedImage, for: .normal)
  }
}

public extension ButtonNode.Configuration {
  static let primary = ButtonNode.Configuration(
    textColor: DesignSystemAsset.background.color,
    borderColor: .clear,
    backgroundColor: .label,
    disabledBackgroundColor: .tertiaryLabel,
    highlightedBackgroundColor: .secondaryLabel
  )

  static let secondary = ButtonNode.Configuration(
    textColor: .label,
    borderColor: .label,
    backgroundColor: DesignSystemAsset.background.color,
    disabledBackgroundColor: UIColor.tertiarySystemBackground,
    highlightedBackgroundColor: .systemFill
  )

  static let text = ButtonNode.Configuration(
    textColor: .label,
    borderColor: .clear,
    backgroundColor: .clear,
    disabledBackgroundColor: .clear,
    highlightedBackgroundColor: .systemFill
  )
}

private extension ButtonNode.Configuration {
  func fillColor(for state: UIControl.State) -> UIColor {
    switch state {
    case .highlighted:
      return backgroundColor.disabled
    case .disabled:
      return highlightedBackgroundColor
    default:
      return backgroundColor
    }
  }

  func borderColor(for state: UIControl.State) -> UIColor {
    switch state {
    case .highlighted:
      return borderColor.disabled
    case .disabled:
      return borderColor
    default:
      return borderColor
    }
  }
}

private extension UIColor {
  var disabled: UIColor {
    self == .clear ? self : withAlphaComponent(0.5)
  }
}
