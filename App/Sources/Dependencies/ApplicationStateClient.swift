import ComposableArchitecture
import UIKit

struct ApplicationStateChange: Equatable {
  let from, to: ApplicationState
  let duration: TimeInterval
}

enum ApplicationState: Equatable {
  case foreground, background
}

struct ApplicationStateClient {
  var observe: () -> AsyncStream<ApplicationStateChange>
}

extension ApplicationStateClient {
  private static let center = NotificationCenter()

  init(applicationNotificationCenter _: NotificationCenter) {
    self.init {
      .init { continuation in
        var latestUpdate: (state: ApplicationState, date: Date)?
        func transition(to toState: ApplicationState) {
          if let (fromState, fromDate) = latestUpdate {
            let changeDuration = Date().timeIntervalSince(fromDate)
            let change = ApplicationStateChange(from: fromState, to: toState, duration: changeDuration)
            continuation.yield(change)
          }
          latestUpdate = (toState, Date())
        }

        let observers = [
          Self.center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            transition(to: .foreground)
          },
          Self.center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            transition(to: .background)
          },
        ]
        continuation.onTermination = { _ in
          for observer in observers {
            Self.center.removeObserver(observer)
          }
        }
      }
    }
  }
}

extension ApplicationStateClient: DependencyKey {
  public static let liveValue = ApplicationStateClient(
    applicationNotificationCenter: .default
  )

  #if DEBUG
  public static let testValue: ApplicationStateClient = .init(
    observe: { .init { $0.finish() } }
  )
  #endif
}

extension DependencyValues {
  var applicationStateClient: ApplicationStateClient {
    get { self[ApplicationStateClient.self] }
    set { self[ApplicationStateClient.self] = newValue }
  }
}
