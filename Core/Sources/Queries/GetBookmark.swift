import GRDB

public struct GetBookmark: PersistenceServiceRead {
  public let articleID: Article.ID
  public init(articleID: Article.ID) {
    self.articleID = articleID
  }

  public func perform(in database: Database) throws -> Bookmark? {
    try Bookmark
      .filter(Bookmark.Columns.articleID == articleID.rawValue)
      .fetchOne(database)
  }
}
