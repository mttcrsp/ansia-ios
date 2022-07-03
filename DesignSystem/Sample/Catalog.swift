import DesignSystem
import UIKit

extension Catalog {
  static let `default` = Catalog(title: "Design System", sections: [
    CatalogSection(title: "Components", items: [
      CatalogItem(title: "Article", builder: ArticleViewController.init),
      CatalogItem(title: "Button", builder: ButtonViewController.init),
      CatalogItem(title: "Disclosure", builder: DisclosureViewController.init),
      CatalogItem(title: "Cell", builder: CellViewController.init),
      CatalogItem(title: "Header", builder: HeaderViewController.init),
      CatalogItem(title: "Published", builder: PublishedAtViewController.init),
      CatalogItem(title: "Separator", builder: SeparatorViewController.init),
    ]),
    CatalogSection(title: "Constants", items: [
      CatalogItem(title: "Typography", builder: TypographyViewController.init),
    ]),
    CatalogSection(title: "Screens", items: [
      CatalogItem(title: "Action", builder: ActionViewController.init),
      CatalogItem(title: "Cross dissolve", builder: SampleCrossDissolveViewController.init),
      CatalogItem(title: "Error", builder: { ErrorViewController() }),
    ]),
  ])
}

struct Catalog {
  let title: String
  let sections: [CatalogSection]
}

struct CatalogSection {
  let title: String
  let items: [CatalogItem]
}

struct CatalogItem {
  let title: String
  let builder: () -> UIViewController
}

extension CatalogSection: Hashable {
  static func == (lhs: CatalogSection, rhs: CatalogSection) -> Bool {
    lhs.title == rhs.title
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }
}

extension CatalogItem: Hashable {
  static func == (lhs: CatalogItem, rhs: CatalogItem) -> Bool {
    lhs.title == rhs.title
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }
}
