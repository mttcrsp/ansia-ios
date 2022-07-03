import Core
import Foundation

struct VideoNotificationRequest: NotificationServiceCalendarRequest, Equatable {
  let body = L10n.VideoNotification.body
  let dateComponents: DateComponents
  let identifier: String
  let title: String
  let repeats = true

  static let day = VideoNotificationRequest(
    identifier: "com.mttcrsp.ansia.notifications.videoDay",
    hour: 13, title: L10n.VideoNotification.titleDay
  )

  static let night = VideoNotificationRequest(
    identifier: "com.mttcrsp.ansia.notifications.videoNight",
    hour: 20, title: L10n.VideoNotification.titleNight
  )

  private init(identifier: String, hour: Int, title: String) {
    self.identifier = identifier
    self.title = title
    dateComponents = DateComponents(hour: hour)
  }
}
