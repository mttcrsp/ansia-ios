import Core
import XCTest

final class NetworkServiceTests: XCTestCase {
  func testPerform() async throws {
    final class Protocol: URLProtocol {
      override class func canInit(with _: URLRequest) -> Bool { true }
      override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
      override func stopLoading() {}
      override func startLoading() {
        client?.urlProtocol(self, didReceive: .init(), cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"key":"value"}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
      }
    }

    struct Request: NetworkRequest {
      typealias Response = [String: String]
      let path: String
    }

    URLProtocol.registerClass(Protocol.self)

    let networkMiddleware = NetworkMiddlewareMock()
    let networkRequest = Request(path: "something")
    let networkService = NetworkServiceLive(urlSession: URLSession.shared, middlewares: [networkMiddleware])
    let networkResponse = try await networkService.perform(networkRequest)
    XCTAssertEqual(networkResponse, ["key": "value"])
    XCTAssertEqual(networkMiddleware.requestWillBeginCallCount, 1)
    XCTAssertEqual(networkMiddleware.requestCallCount, 1)
    XCTAssertEqual(networkMiddleware.requestDidErrorWithCallCount, 0)
  }

  func testPerformError() async throws {
    final class Protocol: URLProtocol {
      static let error = NSError(domain: "test", code: 1)
      override class func canInit(with _: URLRequest) -> Bool { true }
      override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
      override func stopLoading() {}
      override func startLoading() {
        client?.urlProtocol(self, didReceive: .init(), cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didFailWithError: Protocol.error)
      }
    }

    URLProtocol.registerClass(Protocol.self)

    let networkMiddleware = NetworkMiddlewareMock()
    let networkRequest = Request(path: "something")
    let networkService = NetworkServiceLive(urlSession: URLSession.shared, middlewares: [networkMiddleware])

    do {
      _ = try await networkService.perform(networkRequest)
      XCTFail()
    } catch let error as NSError {
      XCTAssertEqual(error.domain, Protocol.error.domain)
      XCTAssertEqual(error.code, Protocol.error.code)
    }

    XCTAssertEqual(networkMiddleware.requestWillBeginCallCount, 1)
    XCTAssertEqual(networkMiddleware.requestCallCount, 0)
    XCTAssertEqual(networkMiddleware.requestDidErrorWithCallCount, 1)
  }

  func testPerformDecodingError() async throws {
    final class Protocol: URLProtocol {
      override class func canInit(with _: URLRequest) -> Bool { true }
      override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
      override func stopLoading() {}
      override func startLoading() {
        client?.urlProtocol(self, didReceive: .init(), cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"key":99}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
      }
    }

    URLProtocol.registerClass(Protocol.self)

    let networkMiddleware = NetworkMiddlewareMock()
    let networkRequest = Request(path: "something")
    let networkService = NetworkServiceLive(urlSession: URLSession.shared, middlewares: [networkMiddleware])

    do {
      _ = try await networkService.perform(networkRequest)
      XCTFail()
    } catch {
      XCTAssertTrue(error is DecodingError)
    }

    XCTAssertEqual(networkMiddleware.requestWillBeginCallCount, 1)
    XCTAssertEqual(networkMiddleware.requestCallCount, 0)
    XCTAssertEqual(networkMiddleware.requestDidErrorWithCallCount, 1)
  }

  private struct Request: NetworkRequest {
    typealias Response = [String: String]
    let path: String
  }
}
