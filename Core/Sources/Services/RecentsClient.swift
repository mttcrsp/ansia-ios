import Foundation

public struct RecentsClient {
  public static let maxRecentsCount = 50
  public var startMonitoring: () -> Void
  public var stopMonitoring: () -> Void

  public init(startMonitoring: @escaping () -> Void, stopMonitoring: @escaping () -> Void) {
    self.startMonitoring = startMonitoring
    self.stopMonitoring = stopMonitoring
  }
}

public extension RecentsClient {
  init(persistenceService: PersistenceService, timerType: TimerProtocol.Type = Timer.self) {
    var timer: TimerProtocol?
    self.init(
      startMonitoring: {
        timer = timerType.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
          Task.detached(priority: .utility) {
            let recentsMaxCount = RecentsClient.maxRecentsCount
            let recentsDelete = DeleteRecents(maxCount: recentsMaxCount)
            try await persistenceService.perform(recentsDelete)
          }
        }
      },
      stopMonitoring: {
        timer?.invalidate()
        timer = nil
      }
    )
  }
}
