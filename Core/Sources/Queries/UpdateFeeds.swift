import GRDB

public struct UpdateFeeds: PersistenceServiceWrite, Hashable {
  public let feeds: [Feed]
  public init(feeds: [Feed]) {
    self.feeds = feeds
  }

  public func perform(in database: Database) throws {
    try Feed.deleteAll(database)
    for feed in feeds {
      try feed.insert(database)
    }
  }
}
