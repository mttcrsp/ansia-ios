import Foundation

public struct Recent: Hashable {
  public let article: Article
  public var createdAt: Date

  public init(article: Article, createdAt: Date) {
    self.article = article
    self.createdAt = createdAt
  }
}
