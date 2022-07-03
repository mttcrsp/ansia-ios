import GRDB

public struct UpdateFeedsArticles: PersistenceServiceWrite, Equatable {
  public let feeds: [Feed.Slug: [Article]]
  public init(feeds: [Feed.Slug: [Article]]) {
    self.feeds = feeds
  }

  public func perform(in database: Database) throws {
    for (slug, _) in feeds {
      try Article
        .filter(Article.Columns.feed == slug.rawValue)
        .deleteAll(database)
    }

    for (_, articles) in feeds {
      for article in articles {
        try article.insert(database)
      }
    }
  }
}
