import Core
import DesignSystem
import SwiftUI

struct ArticlesView: View {
  let entry: ArticlesProvider.Entry

  var body: some View {
    switch entry.result {
    case .failure:
      Text("Qualcosa é andato storto")
        .font(FontFamily.NYTFranklin.bold.swiftUIFont(size: 17))
        .foregroundStyle(DesignSystemAsset.secondaryLabel.swiftUIColor)
        .textCase(.uppercase)
    case let .success((title, items)):
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .lastTextBaseline) {
          Text(title)
            .font(FontFamily.NYTFranklin.bold.swiftUIFont(size: 15))
          Spacer()
          Text("alle \(ArticlesView.formatter.string(from: entry.date))")
            .font(FontFamily.NYTFranklin.medium.swiftUIFont(size: 12))
            .foregroundStyle(DesignSystemAsset.live.swiftUIColor)
        }
        .padding(.bottom, 8)
        Divider()
          .padding(.bottom, 8)
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          Text(item.title)
            .font(
              index == 0
                ? FontFamily.NYTCheltenham.bold.swiftUIFont(size: 17)
                : FontFamily.NYTCheltenham.book.swiftUIFont(size: 15)
            )
            .lineLimit(2)
            .padding(.bottom, 4)
        }
        Spacer(minLength: 0)
      }
      .foregroundStyle(
        DesignSystemAsset.label.swiftUIColor
      )
      .backport.widgetBackground(
        DesignSystemAsset.background.swiftUIColor
      )
    }
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
}
