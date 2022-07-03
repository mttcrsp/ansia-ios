import GRDB

public struct CreateFeedsTable: PersistenceServiceMigration {
  public let identifier = "create feeds table"
  public init() {}
  public func perform(in database: Database) throws {
    try database.create(table: Feed.databaseTableName) { table in
      table.column(Feed.Columns.slug.rawValue).primaryKey(onConflict: .replace).notNull()
      table.column(Feed.Columns.title.rawValue).notNull()
      table.column(Feed.Columns.emoji.rawValue).notNull()
      table.column(Feed.Columns.collection.rawValue).notNull()
      table.column(Feed.Columns.weight.rawValue, .integer).notNull()
    }
  }
}

extension Feed: PersistableRecord, FetchableRecord {
  public static let databaseTableName = "feed"

  enum Columns: String, ColumnExpression {
    case collection
    case emoji
    case slug
    case title
    case weight
  }
}
