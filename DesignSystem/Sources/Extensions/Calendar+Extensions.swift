import Foundation

public extension Calendar {
  func isRecent(_ date1: Date, comparedTo date2: Date = .init(), delta: DateComponents = .init(minute: -60)) -> Bool {
    if let threshold = date(byAdding: delta, to: date2) {
      return compare(threshold, to: date1, toGranularity: .minute) == .orderedAscending
    } else {
      return false
    }
  }
}
