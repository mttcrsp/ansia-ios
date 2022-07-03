import GRDB

public struct UpsertRecent: PersistenceServiceWrite {
  public let recent: Recent
  public init(recent: Recent) {
    self.recent = recent
  }

  public func perform(in database: Database) throws {
    try recent.upsert(database)
  }
}
