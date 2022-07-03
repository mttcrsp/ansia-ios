import Core
import XCTest

final class RecentsClientTests: XCTestCase {
  private var persistenceService: PersistenceServiceMock!
  private var recentsClient: RecentsClient!
  private var timerType = TimerProtocolMock.self

  override func setUp() {
    super.setUp()
    persistenceService = .init()
    recentsClient = .init(persistenceService: persistenceService, timerType: timerType)
  }

  func testMonitor() throws {
    let timer = TimerProtocolMock()

    var completion: ((TimerProtocolMock) -> Void)?
    timerType.scheduledTimerHandler = { _, _, value in
      completion = value
      return timer
    }

    recentsClient.startMonitoring()
    XCTAssertEqual(timerType.scheduledTimerArgValues.first?.0, 60)
    XCTAssertEqual(timerType.scheduledTimerArgValues.first?.1, true)
    XCTAssertNotNil(completion)

    completion?(timer)

    wait {
      let args1 = self.persistenceService.performWriteArgValues as? [DeleteRecents]
      let args2 = [DeleteRecents(maxCount: RecentsClient.maxRecentsCount)]
      return args1?.first?.maxCount == args2.first?.maxCount
    }

    recentsClient.stopMonitoring()
    XCTAssertEqual(timer.invalidateCallCount, 1)
  }
}

extension XCTNSPredicateExpectation {
  convenience init(predicate block: @escaping () -> Bool) {
    let predicate = NSPredicate(block: { _, _ in block() })
    self.init(predicate: predicate, object: nil)
  }
}

extension XCTestCase {
  func wait(file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10, for predicate: @escaping () -> Bool) {
    let expectation = XCTNSPredicateExpectation(predicate: predicate)
    if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
      XCTFail("Expectation failed", file: file, line: line)
    }
  }
}
