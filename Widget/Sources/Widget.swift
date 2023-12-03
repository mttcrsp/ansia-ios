import Core
import DesignSystem
import SwiftUI
import WidgetKit

@main
struct AnsiaWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "article", provider: ArticlesProvider(feedSlug: .main)) { entry in
      WidgetView(entry: entry)
        .backport.widgetBackground(
          DesignSystemAsset.background.swiftUIColor
        )
    }
    .configurationDisplayName("display name")
    .description("description")
  }
}

struct WidgetView: View {
  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
  }()

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
          Text("alle \(Self.formatter.string(from: entry.date))")
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
            .widgetURL(URL(string: ""))
        }
        Spacer(minLength: 0)
      }
      .foregroundStyle(DesignSystemAsset.label.swiftUIColor)
    }
  }
}

struct ArticlesProvider: TimelineProvider {
  struct Entry: TimelineEntry {
    var date = Date()
    var result: Result<(String, [Item]), Error>
  }

  struct Item {
    var id: String
    var title: String
  }

  enum UnexpectedError: Error {
    case dispatchGroupFailure
    case groupNotFound
    case feedNotFound
  }

  let feedSlug: Feed.Slug

  func placeholder(in _: Context) -> Entry {
    .init(result: .success(("Principali", [
      .init(id: "1", title: "La Croazia adotta l'euro ed entra nell'area Schengen"),
      .init(id: "2", title: "Meta, milioni di persone continuano a usare Instagram in Iran"),
    ])))
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(placeholder(in: context))
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    do {
      guard let applicationDatabaseURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mttcrsp.ansia")?
        .appendingPathComponent("db")
        .appendingPathExtension("sqlite")
      else { throw UnexpectedError.groupNotFound }

      let migrations: [PersistenceServiceMigration] = [
        CreateArticlesTable(),
        CreateFeedsTable(),
        CreateBookmarksTable(),
        CreateRecentsTable(),
      ]

      let persistenceService = PersistenceServiceLive(migrations: migrations)
      try persistenceService.load(at: applicationDatabaseURL.path())

      Task {
        do {
          let networkService = NetworkServiceLive(urlSession: .shared)
          let response = try await networkService.perform(
            ArticlesByFeedRequest(slug: feedSlug)
          )
          try await persistenceService.perform(
            UpdateFeedArticles(slug: feedSlug, articles: response.articles)
          )
        } catch { /* do nothing */ }

        let result: Result<(String, [Item]), Error>
        do {
          let feedQuery = GetFeedBySlug(slug: feedSlug)
          let feed = try await persistenceService.perform(feedQuery)
          let articlesQuery = GetArticlesByFeed(slug: feedSlug, limit: 2)
          let articles = try await persistenceService.perform(articlesQuery)
          if let feed {
            result = .success((feed.title, articles.map(Item.init)))
          } else {
            result = .failure(UnexpectedError.feedNotFound)
          }
        } catch {
          result = .failure(error)
        }
        completion(.init(entries: [.init(result: result)], policy: .atEnd))
      }
    } catch {
      completion(.init(entries: [.init(result: .failure(error))], policy: .atEnd))
    }
  }
}

extension ArticlesProvider.Item: Identifiable {}

private extension ArticlesProvider.Item {
  init(article: Article) {
    self.init(id: article.articleID.rawValue, title: article.title)
  }
}

struct Backport<Content> {
  let content: Content
  init(_ content: Content) {
    self.content = content
  }
}

extension View {
  var backport: Backport<Self> {
    Backport(self)
  }
}

extension Backport where Content: View {
  @ViewBuilder func widgetBackground(_ backgroundView: some View) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) {
        backgroundView
      }
    } else {
      content.background(backgroundView)
    }
  }
}
