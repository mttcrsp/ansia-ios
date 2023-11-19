import Combine
import ComposableArchitecture
import Core
import DesignSystem
import UIKit

final class OnboardingViewController: CrossDissolveViewController {
  private let viewStore: ViewStoreOf<OnboardingReducer>
  private var cancellables: Set<AnyCancellable> = []
  private weak var sectionsViewController: OnboardingSectionsViewController?
  private weak var errorViewController: ErrorViewController?

  init(store: StoreOf<OnboardingReducer>) {
    viewStore = ViewStore(store, observe: { $0 })
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    viewStore.publisher
      .map(\.didFail)
      .removeDuplicates()
      .sink { [weak self] didFail in
        if didFail {
          self?.showError()
        } else {
          self?.showSections()
        }
      }
      .store(in: &cancellables)

    viewStore.publisher.minimumSectionsAlert
      .sink { [weak self] alert in
        if let alert {
          self?.showAlert(alert)
        }
      }
      .store(in: &cancellables)

    viewStore.publisher
      .map(\.sections)
      .removeDuplicates()
      .sink { [weak self] feeds in
        self?.sectionsViewController?.configuration.feeds = feeds
      }
      .store(in: &cancellables)

    viewStore.send(.didLoad)
  }

  private func showAlert(_ state: AlertState<OnboardingReducer.Action>) {
    let alertController = UIAlertController(state: state) { [weak self] action in
      if let action {
        self?.viewStore.send(action)
      }
    }
    present(alertController, animated: true)
  }

  private func showError() {
    let errorViewController = ErrorViewController()
    self.errorViewController = errorViewController
    setContentViewController(errorViewController, animated: true)
  }

  private func showSections() {
    let sectionsViewController = OnboardingSectionsViewController(
      configuration: .init(feeds: viewStore.sections)
    )
    sectionsViewController.onConfirmTap = { [weak self, weak sectionsViewController] in
      if let sectionsViewController {
        let selectedFeeds = Array(sectionsViewController.configuration.selectedFeeds)
        self?.viewStore.send(.sectionsConfirmTapped(selectedFeeds))
      }
    }
    self.sectionsViewController = sectionsViewController
    setContentViewController(sectionsViewController, animated: true)
  }
}
