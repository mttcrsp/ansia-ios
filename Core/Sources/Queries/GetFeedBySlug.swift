import GRDB

public struct GetFeedBySlug: PersistenceServiceRead {
  public let slug: Feed.Slug
  public init(slug: Feed.Slug) {
    self.slug = slug
  }

  public func perform(in database: Database) throws -> Feed? {
    try Feed
      .filter(Feed.Columns.slug == slug.rawValue)
      .fetchOne(database)
  }
}
