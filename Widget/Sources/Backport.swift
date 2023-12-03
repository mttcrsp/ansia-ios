import SwiftUI

struct Backport<Content> {
  let content: Content
  init(_ content: Content) {
    self.content = content
  }
}

extension View {
  var backport: Backport<Self> {
    Backport(self)
  }
}

extension Backport where Content: View {
  @ViewBuilder func widgetBackground(_ backgroundView: some View) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) {
        backgroundView
      }
    } else {
      content.background(backgroundView)
    }
  }
}
