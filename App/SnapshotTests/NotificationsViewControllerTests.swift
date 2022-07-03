@testable
import App
import ComposableArchitecture
import HammerTests
import SnapshotTesting
import XCTest

final class NotificationsViewControllerTests: XCTestCase {
  private typealias Action = NotificationsReducer.Action
  private typealias State = NotificationsReducer.State

  func testStates() {
    let states: [State] = [
      .init(notificationsStatus: .disabled),
      .init(notificationsStatus: .enabled(
        .init(isVideoDayEnabled: true)
      )),
      .init(notificationsStatus: .enabled(
        .init(isVideoNightEnabled: true)
      )),
      .init(notificationsStatus: .enabled(
        .init(
          isVideoDayEnabled: true,
          isVideoNightEnabled: true
        )
      )),
    ]

    for state in states {
      let store = Store(initialState: state, reducer: NotificationsReducer())
      let vc = NotificationsViewController(store: store)
      let nc = UINavigationController(rootViewController: vc)
      assertSnapshot(matching: nc, as: .image(on: .iPhone12))
    }
  }

  func testEvents() throws {
    let state = State(
      notificationsStatus: .enabled(
        .init(
          isVideoDayEnabled: true,
          isVideoNightEnabled: true
        )
      )
    )

    var actions: [Action] = []
    let reducer = Reduce<State, Action> { _, action in
      actions.append(action)
      return .none
    }

    let vc = NotificationsViewController(store: .init(initialState: state, reducer: reducer))
    let generator = try EventGenerator(viewController: vc)

    let allIdentifier = "all_switch"
    try generator.waitUntilHittable(allIdentifier, timeout: 1)
    try generator.fingerTap(at: allIdentifier)

    let dayIdentifier = "video_day_switch"
    try generator.waitUntilHittable(dayIdentifier, timeout: 1)
    try generator.fingerTap(at: dayIdentifier)

    let nightIdentifier = "video_night_switch"
    try generator.waitUntilHittable(nightIdentifier, timeout: 1)
    try generator.fingerTap(at: nightIdentifier)

    let predicate = NSPredicate { _, _ in
      actions == [
        .didLoad,
        .allNotificationsToggled(false),
        .videoDayToggled(false),
        .videoNightToggled(false),
      ]
    }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 3), .completed)
  }
}
