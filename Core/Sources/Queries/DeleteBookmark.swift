import GRDB

public struct DeleteBookmark: PersistenceServiceWrite {
  public let articleID: Article.ID
  public init(articleID: Article.ID) {
    self.articleID = articleID
  }

  public func perform(in database: Database) throws {
    try Bookmark
      .filter(Bookmark.Columns.articleID == articleID.rawValue)
      .deleteAll(database)
  }
}
