import GRDB

public struct DeleteRecent: PersistenceServiceWrite {
  public let articleID: Article.ID
  public init(articleID: Article.ID) {
    self.articleID = articleID
  }

  public func perform(in database: Database) throws {
    try Recent
      .filter(Recent.Columns.articleID == articleID.rawValue)
      .deleteAll(database)
  }
}
