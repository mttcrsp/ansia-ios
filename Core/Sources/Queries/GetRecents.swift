import GRDB

public struct GetRecents: PersistenceServiceRead {
  public let limit: Int
  public init(limit: Int) {
    self.limit = limit
  }

  public func perform(in database: Database) throws -> [Recent] {
    try Recent
      .order(Recent.Columns.createdAt.desc)
      .limit(limit)
      .fetchAll(database)
  }
}
