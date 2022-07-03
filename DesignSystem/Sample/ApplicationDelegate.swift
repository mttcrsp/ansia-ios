import UIKit

@UIApplicationMain
final class ApplicationDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let catalogViewController = CatalogViewController()
    let navigationController = UINavigationController(rootViewController: catalogViewController)
    window = UIWindow()
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
    return true
  }
}

private final class CatalogViewController: UITableViewController {
  private let catalog: Catalog

  init(catalog: Catalog = .default) {
    self.catalog = catalog
    super.init(style: .plain)
    title = catalog.title
    navigationItem.backButtonTitle = ""
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
  }

  override func numberOfSections(in _: UITableView) -> Int {
    catalog.sections.count
  }

  override func tableView(_: UITableView, numberOfRowsInSection index: Int) -> Int {
    section(at: index).items.count
  }

  override func tableView(_: UITableView, titleForHeaderInSection index: Int) -> String? {
    section(at: index).title
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = item(at: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)

    var contentConfiguration = cell.defaultContentConfiguration()
    contentConfiguration.text = item.title

    cell.accessoryType = .disclosureIndicator
    cell.contentConfiguration = contentConfiguration
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = item(at: indexPath)
    let itemViewController = item.builder()
    itemViewController.title = item.title
    show(itemViewController, sender: nil)
  }

  private func section(at index: Int) -> CatalogSection {
    catalog.sections[index]
  }

  private func item(at indexPath: IndexPath) -> CatalogItem {
    section(at: indexPath.section).items[indexPath.row]
  }
}

private extension UIView {
  static var reuseIdentifier: String {
    String(describing: self)
  }
}
