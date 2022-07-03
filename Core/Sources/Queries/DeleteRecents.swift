import GRDB

public struct DeleteRecents: PersistenceServiceWrite, Hashable {
  public let maxCount: Int
  public init(maxCount: Int) {
    self.maxCount = maxCount
  }

  public func perform(in database: Database) throws {
    let lastValid = try Recent
      .order(Recent.Columns.createdAt.desc)
      .limit(1, offset: maxCount - 1)
      .fetchOne(database)

    if let lastValid {
      try Recent
        .filter(Recent.Columns.createdAt < lastValid.createdAt)
        .deleteAll(database)
    }
  }
}
