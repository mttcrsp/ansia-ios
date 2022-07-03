import GRDB

public struct GetArticlesByFeed: PersistenceServiceRead {
  public let slug: Feed.Slug
  public let limit: Int
  public init(slug: Feed.Slug, limit: Int) {
    self.slug = slug
    self.limit = limit
  }

  public func perform(in database: Database) throws -> [Article] {
    try Article
      .filter(Article.Columns.feed == slug.rawValue)
      .order(Article.Columns.publishedAt.desc)
      .limit(limit)
      .fetchAll(database)
  }
}
