import SwiftUI
import WidgetKit

@main
struct AnsiaWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "article", provider: ArticlesProvider()) { entry in
      WidgetView(entry: entry)
        .padding()
        .background()
    }
    .configurationDisplayName("display name")
    .description("description")
  }
}

struct WidgetView: View {
  let entry: ArticlesProvider.Entry
  var body: some View {
    Text(entry.date.description)
  }
}

struct ArticlesProvider: TimelineProvider {
  struct Entry: TimelineEntry {
    var date: Date
  }

  func placeholder(in _: Context) -> Entry {
    .init(date: .now)
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    completion(.init(entries: [placeholder(in: context)], policy: .atEnd))
  }
}
