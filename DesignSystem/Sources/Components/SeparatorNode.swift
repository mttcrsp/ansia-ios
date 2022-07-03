import AsyncDisplayKit

public final class SeparatorNode: ASDisplayNode {
  public struct Configuration: Equatable {
    let backgroundColor: UIColor
    let height: CGFloat
  }

  public init(configuration: Configuration = .default) {
    super.init()
    backgroundColor = configuration.backgroundColor
    style.width = .init(unit: .fraction, value: 1)
    style.height = .init(unit: .points, value: configuration.height)
  }
}

public extension SeparatorNode.Configuration {
  static let `default` = SeparatorNode.Configuration(
    backgroundColor: .label.withAlphaComponent(0.2),
    height: 1 / UIScreen.main.scale
  )

  static let prominent = SeparatorNode.Configuration(
    backgroundColor: .label,
    height: 2
  )
}
