import Core
import DesignSystem
import SwiftUI

struct WidgetArticlesView: View {
  let entry: WidgetArticlesProvider.Entry
  var body: some View {
    Group {
      switch entry.result {
      case .failure:
        ErrorView()
      case let .success((title, items)):
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .lastTextBaseline) {
            Text(title)
              .font(FontFamily.NYTFranklin.bold.swiftUIFont(size: 15))
            Spacer()
            Text("alle \(WidgetArticlesView.formatter.string(from: entry.date))")
              .font(FontFamily.NYTFranklin.medium.swiftUIFont(size: 12))
              .foregroundStyle(DesignSystemAsset.live.swiftUIColor)
          }
          Divider()
          VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
              Text(item.title)
                .font(
                  index == 0
                    ? FontFamily.NYTCheltenham.bold.swiftUIFont(size: 17)
                    : FontFamily.NYTCheltenham.book.swiftUIFont(size: 15)
                )
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: index != items.count - 1)
            }
          }
        }
        .foregroundStyle(
          DesignSystemAsset.label.swiftUIColor
        )
        Spacer(minLength: 0)
      }
    }
    .backport.widgetBackground(
      DesignSystemAsset.background.swiftUIColor
    )
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()
}

struct WidgetArticleView: View {
  let entry: WidgetArticlesProvider.Entry
  var body: some View {
    Group {
      if let item {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
              Text(item.title)
                .font(FontFamily.NYTCheltenham.bold.swiftUIFont(size: 17))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
              if let description = item.description {
                Text(description)
                  .font(FontFamily.NYTCheltenham.book.swiftUIFont(size: 15))
              }
            }
            if let url = item.imageURL {
              Spacer()
              AsyncImage(url: url)
                .frame(width: 72, height: 72)
            }
          }
        }
        .foregroundStyle(
          DesignSystemAsset.label.swiftUIColor
        )
      } else {
        ErrorView()
      }
    }
    .backport.widgetBackground(
      DesignSystemAsset.background.swiftUIColor
    )
  }

  private var item: WidgetArticlesProvider.Item? {
    if case let .success((_, items)) = entry.result {
      items.first
    } else {
      nil
    }
  }

  private static let formatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = .init(identifier: "it_IT")
    return formatter
  }()
}

private struct ErrorView: View {
  var body: some View {
    Text("Qualcosa é andato storto")
      .font(FontFamily.NYTFranklin.bold.swiftUIFont(size: 17))
      .foregroundStyle(DesignSystemAsset.secondaryLabel.swiftUIColor)
      .textCase(.uppercase)
  }
}
