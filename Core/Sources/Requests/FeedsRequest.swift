public struct FeedsRequest: NetworkRequest, Hashable {
  public struct Response: Decodable {
    public let feeds: [Feed]
  }

  public let path = "/v1/feeds"
  public init() {}
}
