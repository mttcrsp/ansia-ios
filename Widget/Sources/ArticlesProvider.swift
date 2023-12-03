import Core
import WidgetKit

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
          let articlesQuery = GetArticlesByFeed(slug: feedSlug, limit: 3)
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
