import GRDB

public struct GetFeedsBySlugs: PersistenceServiceRead {
  public let slugs: [Feed.Slug]
  public init(slugs: [Feed.Slug]) {
    self.slugs = slugs
  }

  public func perform(in database: Database) throws -> [Feed] {
    try Feed
      .filter(slugs.map(\.rawValue).contains(Feed.Columns.slug))
      .fetchAll(database)
  }
}
