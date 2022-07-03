import GRDB

public struct InsertBookmark: PersistenceServiceWrite {
  public let bookmark: Bookmark
  public init(bookmark: Bookmark) {
    self.bookmark = bookmark
  }

  public func perform(in database: Database) throws {
    try bookmark.insert(database)
  }
}
