public struct ArticlesByFeedRequest: NetworkRequest, Hashable {
  public struct Response: Decodable {
    public let articles: [Article]
  }

  public let slug: Feed.Slug
  public init(slug: Feed.Slug) {
    self.slug = slug
  }

  public var path: String {
    "/v1/feeds/\(slug)/articles"
  }
}
