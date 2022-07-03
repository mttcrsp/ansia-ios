public struct VideosRequest: NetworkRequest, Hashable {
  public struct Response: Decodable {
    public let videos: [Video]
  }

  public let path = "v1/videos"
  public init() {}
}
