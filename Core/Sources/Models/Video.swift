import Foundation
import Tagged

public struct Video: Decodable, Hashable {
  public typealias ID = Tagged<Video, String>

  public let videoID: ID
  public let title: String
  public let videoURL: URL
  public let publishedAt: Date
}

public extension Video {
  func hash(into hasher: inout Hasher) {
    hasher.combine(publishedAt)
  }

  static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    lhs.publishedAt == rhs.publishedAt
  }
}

extension Video {
  enum CodingKeys: String, CodingKey {
    case publishedAt = "published_at"
    case title
    case videoID = "video_id"
    case videoURL = "video_url"
  }
}
