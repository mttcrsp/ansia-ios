import Foundation

/// @mockable
public protocol NetworkService {
  func perform<Request>(_ request: Request) async throws -> Request.Response where Request: NetworkRequest
}

public protocol NetworkRequest {
  associatedtype Response: Decodable
  var path: String { get }
  var queryItems: [URLQueryItem] { get }
}

public extension NetworkRequest {
  var queryItems: [URLQueryItem] {
    []
  }
}

/// @mockable
public protocol NetworkMiddleware {
  func requestWillBegin(_ request: URLRequest)
  func request(_ request: URLRequest, didCompleteWith data: Data, response: URLResponse)
  func request(_ request: URLRequest, didErrorWith error: Error)
}

extension NetworkMiddleware {
  func requestWillBegin(_: URLRequest) {}
  func request(_: URLRequest, didCompleteWith _: Data?, response _: URLResponse) {}
  func request(_: URLRequest, didErrorWith _: Error) {}
}
