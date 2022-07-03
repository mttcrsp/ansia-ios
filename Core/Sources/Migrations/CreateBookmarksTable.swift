import GRDB

public struct CreateBookmarksTable: PersistenceServiceMigration {
  public let identifier = "create bookmarks table"
  public init() {}
  public func perform(in database: Database) throws {
    try database.create(table: Bookmark.databaseTableName) { table in
      table.column(Bookmark.Columns.articleID.rawValue).primaryKey()
      table.column(Bookmark.Columns.feed.rawValue).notNull()
      table.column(Bookmark.Columns.url.rawValue).notNull()
      table.column(Bookmark.Columns.title.rawValue).notNull()
      table.column(Bookmark.Columns.description.rawValue)
      table.column(Bookmark.Columns.content.rawValue).notNull()
      table.column(Bookmark.Columns.keywords.rawValue)
      table.column(Bookmark.Columns.imageURL.rawValue)
      table.column(Bookmark.Columns.publishedAt.rawValue).notNull()
      table.column(Bookmark.Columns.createdAt.rawValue).notNull()
    }
  }
}

extension Bookmark: PersistableRecord, FetchableRecord {
  public static let databaseTableName = "bookmark"

  public init(row: Row) throws {
    createdAt = row[Columns.createdAt.rawValue]
    article = try Article(row: row)
  }

  public func encode(to container: inout PersistenceContainer) throws {
    container[Columns.createdAt.rawValue] = createdAt
    try article.encode(to: &container)
  }
}

extension Bookmark {
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
