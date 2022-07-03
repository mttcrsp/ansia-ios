import GRDB

public struct UpdateFeedArticles: PersistenceServiceWrite, Hashable {
  public let articles: [Article]
  public let slug: Feed.Slug
  public init(slug: Feed.Slug, articles: [Article]) {
    self.articles = articles
    self.slug = slug
  }

  public func perform(in database: Database) throws {
    try Article
      .filter(Article.Columns.feed == slug.rawValue)
      .deleteAll(database)

    for article in articles {
      try article.insert(database)
    }
  }
}
