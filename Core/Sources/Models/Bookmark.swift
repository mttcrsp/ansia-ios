import Foundation

public struct Bookmark: Hashable {
  public let article: Article
  public let createdAt: Date

  public init(article: Article, createdAt: Date) {
    self.article = article
    self.createdAt = createdAt
  }
}
