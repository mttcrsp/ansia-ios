import GRDB

public struct GetFeedsByCollection: PersistenceServiceRead, Hashable {
  public let collection: Feed.Collection
  public init(collection: Feed.Collection) {
    self.collection = collection
  }

  public func perform(in database: Database) throws -> [Feed] {
    try Feed
      .filter(Feed.Columns.collection == collection.rawValue)
      .order(Feed.Columns.weight)
      .fetchAll(database)
  }
}
