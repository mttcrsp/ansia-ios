import GRDB

public struct GetBookmarks: PersistenceServiceRead {
  public let limit: Int
  public let offset: Int
  public init(limit: Int, offset: Int) {
    self.offset = offset
    self.limit = limit
  }

  public func perform(in database: Database) throws -> [Bookmark] {
    try Bookmark
      .order(Bookmark.Columns.createdAt.desc)
      .limit(limit, offset: offset)
      .fetchAll(database)
  }
}
