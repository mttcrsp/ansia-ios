import Core
import DesignSystem
import SwiftUI
import WidgetKit

@main
struct AnsiaWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "article", provider: ArticlesProvider()) { entry in
      WidgetView(entry: entry)
    }
    .configurationDisplayName("display name")
    .description("description")
  }
}

struct WidgetView: View {
  let entry: ArticlesProvider.Entry
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Top Stories")
        .font(FontFamily.NYTFranklin.bold.swiftUIFont(size: 14))
      Spacer(minLength: 8)
      Text(AttributedString(PublishedAtFormatter().attributedString(for: entry.items[0].publishedAt)))
        .padding(.bottom, 4)
      Text(entry.items[0].title)
        .font(FontFamily.NYTCheltenham.bold.swiftUIFont(size: 16))
        .lineLimit(2)
        .padding(.bottom, 4)
        .widgetURL(URL(string: ""))
      Divider()
        .padding(.bottom, 4)
      Text(entry.items[1].title)
        .font(FontFamily.NYTCheltenham.book.swiftUIFont(size: 12))
        .lineLimit(2)
        .widgetURL(URL(string: ""))
      Spacer(minLength: 0)
    }
    .foregroundStyle(DesignSystemAsset.label.swiftUIColor)
  }
}

struct ArticlesProvider: TimelineProvider {
  struct Entry: TimelineEntry {
    struct Item {
      var title: String
      var publishedAt: Date
    }

    var date: Date
    var items: [Item]
  }

  func placeholder(in _: Context) -> Entry {
    .init(
      date: Date(),
      items: [
        .init(title: "A $52,112 Air Ambulance Ride: Coronavirus Patients Battle Surprise Bills", publishedAt: Date().addingTimeInterval(-100)),
        .init(title: "The Day in Polls: More Clarity in North Carolina", publishedAt: Date().addingTimeInterval(-200)),
      ]
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(placeholder(in: context))
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    do {
      let fileManager = FileManager.default
      let applicationSupportURL = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.mttcrsp.ansia"
      )!
      let applicationDatabaseURL = applicationSupportURL
        .appendingPathComponent("db")
        .appendingPathExtension("sqlite")

      let migrations: [PersistenceServiceMigration] = [
        CreateArticlesTable(),
        CreateFeedsTable(),
        CreateBookmarksTable(),
        CreateRecentsTable(),
      ]

      let query = GetArticlesByFeed(slug: .main, limit: 2)
      let persistenceService = PersistenceServiceLive(migrations: migrations)
      try persistenceService.load(at: applicationDatabaseURL.path())
      persistenceService.perform(query) { result in
        switch result {
        case .failure:
          completion(
            .init(
              entries: [
                .init(date: Date(), items: [
                  .init(title: "A $52,112 Air Ambulance Ride: Coronavirus Patients Battle Surprise Bills", publishedAt: Date().addingTimeInterval(-100)),
                  .init(title: "The Day in Polls: More Clarity in North Carolina", publishedAt: Date().addingTimeInterval(-200)),
                ]),
              ],
              policy: .atEnd
            )
          )
        case let .success(articles):
          print(articles)
          completion(
            .init(
              entries: [
                .init(
                  date: Date(),
                  items: articles.map { article in
                    .init(title: article.title, publishedAt: article.publishedAt)
                  }
                ),
              ],
              policy: .atEnd
            )
          )
//          completion(
//            .init(
//              entries: [
//                .init(date: Date(), items: feed),
//              ],
//              policy: .atEnd
//            )
//          )
        }
      }
    } catch {
      print(error)
      completion(
        .init(
          entries: [
            .init(date: Date(), items: [
              .init(title: "A $52,112 Air Ambulance Ride: Coronavirus Patients Battle Surprise Bills", publishedAt: Date().addingTimeInterval(-100)),
              .init(title: "The Day in Polls: More Clarity in North Carolina", publishedAt: Date().addingTimeInterval(-200)),
            ]),
          ],
          policy: .atEnd
        )
      )
    }
  }
}
