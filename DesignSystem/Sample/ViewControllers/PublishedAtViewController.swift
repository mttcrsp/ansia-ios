import AsyncDisplayKit
import DesignSystem

final class PublishedAtViewController: ASDKViewController<ASDisplayNode> {
  override init() {
    super.init(node: .init())

    let calendar = Locale.italian.calendar
    let date = Date()
    let dates: [Date] = [
      calendar.date(byAdding: .init(second: -1), to: date),
      calendar.date(byAdding: .init(minute: -9), to: date),
      calendar.date(byAdding: .init(minute: -10), to: date),
      calendar.date(byAdding: .init(hour: -1), to: date),
      calendar.date(byAdding: .init(day: -1), to: date),
    ].compactMap { $0 }

    let nodes = dates.map { date in
      PublishedAtNode(configuration: .init(publishedAt: date))
    }

    node.automaticallyManagesSubnodes = true
    node.backgroundColor = DesignSystemAsset.background.color
    node.layoutSpecBlock = { _, _ in
      ASCenterLayoutSpec(
        horizontalPosition: .center,
        verticalPosition: .center,
        sizingOption: .minimumSize,
        child: ASStackLayoutSpec(
          direction: .vertical,
          spacing: 16,
          justifyContent: .start,
          alignItems: .start,
          children: nodes
        )
      )
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func tapped() {
    print(#function, Date())
  }
}
