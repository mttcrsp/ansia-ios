import Foundation
import Tagged

public struct Article: Hashable, Codable {
  public typealias ID = Tagged<Article, String>

  public let articleID: ID
  public let url: URL
  public let feed: String
  public let title: String
  public let description: String?
  public let content: String
  public let keywords: [String]
  public let imageURL: URL?
  public let publishedAt: Date
}

public extension Article {
  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }

  static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    lhs.title == rhs.title
  }
}

extension Article {
  enum CodingKeys: String, CodingKey {
    case articleID = "article_id"
    case content
    case description
    case feed
    case imageURL = "image_url"
    case keywords
    case publishedAt = "published_at"
    case title
    case url
  }
}
