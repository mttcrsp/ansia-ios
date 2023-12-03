import Core
import DesignSystem
import SwiftUI
import WidgetKit

@main
struct Widget: SwiftUI.Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "feed", provider: WidgetArticlesProvider(feedSlug: .main)) { entry in
      WidgetArticlesView(entry: entry)
    }
    .configurationDisplayName("Principali")
    .description("Le ultime notizie dalla sezione Principali")
    .supportedFamilies([.systemMedium])
  }
}
