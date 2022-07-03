import GRDB

public struct CreateArticlesTable: PersistenceServiceMigration {
  public let identifier = "create articles table"
  public init() {}
  public func perform(in database: Database) throws {
    try database.create(table: Article.databaseTableName) { table in
      table.column(Article.Columns.articleID.rawValue).notNull()
      table.column(Article.Columns.feed.rawValue).notNull()
      table.column(Article.Columns.url.rawValue).notNull()
      table.column(Article.Columns.title.rawValue).notNull()
      table.column(Article.Columns.description.rawValue)
      table.column(Article.Columns.content.rawValue).notNull()
      table.column(Article.Columns.keywords.rawValue)
      table.column(Article.Columns.imageURL.rawValue)
      table.column(Article.Columns.publishedAt.rawValue).notNull()
    }
  }
}

extension Article: PersistableRecord, FetchableRecord {
  public static let databaseTableName = "article"
  typealias Columns = CodingKeys
}

extension Article.Columns: ColumnExpression {}
