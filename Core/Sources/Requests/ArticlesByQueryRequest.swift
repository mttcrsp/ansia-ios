import Foundation

public struct ArticlesByQueryRequest: NetworkRequest {
  public struct Response: Decodable {
    public let articles: [Article]
  }

  public let query: String
  public init(query: String) {
    self.query = query
  }

  public let path = "/v1/articles"
  public var queryItems: [URLQueryItem] {
    [.init(name: "query", value: query)]
  }
}
