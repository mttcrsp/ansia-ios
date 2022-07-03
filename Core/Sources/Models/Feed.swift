import Tagged

public struct Feed: Equatable, Hashable, Codable {
  public typealias Collection = Tagged<Feed, String>
  public typealias Slug = Tagged<Feed, String>

  public let slug: Slug
  public let title: String
  public let collection: Collection
  public let emoji: String
  public let weight: Int

  public init(slug: Slug, title: String, collection: Collection, emoji: String, weight: Int) {
    self.slug = slug
    self.title = title
    self.collection = collection
    self.emoji = emoji
    self.weight = weight
  }
}

public extension Feed.Collection {
  static let main: Feed.Collection = "principali"
  static let local: Feed.Collection = "regionali"
}

public extension Feed.Slug {
  static let home: Feed.Slug = "principali"
}
