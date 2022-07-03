import Foundation

public final class NetworkServiceLive: NetworkService {
  public let middlewares: [NetworkMiddleware]
  public let urlSession: URLSession

  public init(urlSession: URLSession, middlewares: [NetworkMiddleware] = []) {
    self.middlewares = middlewares
    self.urlSession = urlSession
  }

  public func perform<Request: NetworkRequest>(_ request: Request) async throws -> Request.Response {
    let urlRequest = URLRequest(url: request.url)
    for middleware in middlewares {
      middleware.requestWillBegin(urlRequest)
    }

    do {
      let (data, urlResponse) = try await urlSession.data(for: urlRequest)
      let response = try request.decode(data: data, response: urlResponse)
      for middleware in middlewares {
        middleware.request(urlRequest, didCompleteWith: data, response: urlResponse)
      }
      return response
    } catch {
      for middleware in middlewares {
        middleware.request(urlRequest, didErrorWith: error)
      }
      throw error
    }
  }
}

private extension NetworkRequest {
  func decode(data: Data?, response _: URLResponse?) throws -> Response {
    do {
      return try JSONDecoder.default.decode(Response.self, from: data ?? Data())
    } catch {
      throw error
    }
  }

  var url: URL {
    #if targetEnvironment(macCatalyst)
    let url = URL.base.appendingPathComponent(path)
    #else
    let url = URL.base.appending(components: path)
    #endif
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.queryItems = queryItems
    return components?.url ?? url
  }
}

private extension URL {
  static let base = URL(string: "https://ansiabe.fly.dev")!
}
