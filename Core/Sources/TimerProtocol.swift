import Foundation

/// @mockable
public protocol TimerProtocol {
  static func scheduledTimer(withTimeInterval: TimeInterval, repeats: Bool, block: @escaping (TimerProtocol) -> Void) -> TimerProtocol
  func invalidate()
}

extension Timer: TimerProtocol {
  public static func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (TimerProtocol) -> Void) -> TimerProtocol {
    scheduledTimer(withTimeInterval: interval, repeats: repeats) { (timer: Timer) in
      block(timer)
    }
  }
}
