import GRDB

public struct CreateRecentsTable: PersistenceServiceMigration {
  public let identifier = "create recents table"
  public init() {}
  public func perform(in database: Database) throws {
    try database.create(table: Recent.databaseTableName) { table in
      table.column(Recent.Columns.articleID.rawValue).primaryKey()
      table.column(Recent.Columns.feed.rawValue).notNull()
      table.column(Recent.Columns.url.rawValue).notNull()
      table.column(Recent.Columns.title.rawValue).notNull()
      table.column(Recent.Columns.description.rawValue)
      table.column(Recent.Columns.content.rawValue).notNull()
      table.column(Recent.Columns.keywords.rawValue)
      table.column(Recent.Columns.imageURL.rawValue)
      table.column(Recent.Columns.publishedAt.rawValue).notNull()
      table.column(Recent.Columns.createdAt.rawValue).notNull()
    }
  }
}

extension Recent: PersistableRecord, FetchableRecord {
  public static let databaseTableName = "recent"

  public init(row: Row) throws {
    createdAt = row[Columns.createdAt.rawValue]
    article = try Article(row: row)
  }

  public func encode(to container: inout PersistenceContainer) throws {
    container[Columns.createdAt.rawValue] = createdAt
    try article.encode(to: &container)
  }
}

extension Recent {
  enum Columns: String, ColumnExpression {
    case articleID = "article_id"
    case content
    case createdAt = "created_at"
    case description
    case feed
    case imageURL = "image_url"
    case keywords
    case publishedAt = "published_at"
    case title
    case url
  }
}
