import Foundation

public final class NetworkLoggingMiddleware {
  public init() {}
}

extension NetworkLoggingMiddleware: NetworkMiddleware {
  public func requestWillBegin(_ request: URLRequest) {
    guard let url = request.url else { return }
    print("📤", url)
  }

  public func request(_ request: URLRequest, didCompleteWith _: Data, response: URLResponse) {
    guard let url = request.url, let httpResponse = response as? HTTPURLResponse else { return }
    print("📥", url, httpResponse.statusCode, httpResponse.expectedContentLength)
  }

  public func request(_ request: URLRequest, didErrorWith error: Error) {
    guard let url = request.url else { return }
    print("❌", url, error)
  }
}
