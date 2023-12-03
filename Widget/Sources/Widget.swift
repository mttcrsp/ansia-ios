import Core
import DesignSystem
import SwiftUI
import WidgetKit

@main
struct Widget: SwiftUI.Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "article", provider: ArticlesProvider(feedSlug: .main)) { entry in
      ArticlesView(entry: entry)
    }
    .configurationDisplayName("Principali")
    .description("Le ultime notizie dalla sezione Principali")
    .supportedFamilies([.systemMedium])
  }
}
