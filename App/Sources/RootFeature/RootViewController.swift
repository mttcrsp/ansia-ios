import Combine
import ComposableArchitecture
import Core
import DesignSystem
import UIKit

final class RootViewController: CrossDissolveViewController {
  private weak var onboardingViewController: UIViewController?
  private weak var settingsViewController: SettingsViewController?
  private weak var tabBarViewController: UITabBarController?

  private let store: StoreOf<RootReducer>
  private let viewStore: ViewStoreOf<RootReducer>
  private var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<RootReducer>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let navigationController = UINavigationController()
    navigationController.setNavigationBarHidden(true, animated: false)
    setContentViewController(navigationController, animated: false)

    viewStore.publisher.showsError
      .sink { [weak self] showsError in
        if showsError {
          let errorViewController = ErrorViewController()
          errorViewController.onActionTap = { [weak self] in
            self?.viewStore.send(.setupRetryTapped)
          }
          self?.setContentViewController(errorViewController, animated: false)
        } else {
          self?.setContentViewController(navigationController, animated: false)
        }
      }
      .store(in: &cancellables)

    let moreStore = store.scope(state: \.more, action: RootReducer.Action.more)
    let moreViewController = MoreViewController(store: moreStore)
    let moreNavigationController = UINavigationController(rootViewController: moreViewController)

    store.scope(state: \.today, action: RootReducer.Action.today)
      .ifLet { [weak self] store in
        let forYouViewController = TodayViewController(store: store)
        let forYouNavigationController = UINavigationController(rootViewController: forYouViewController)

        let tabBarViewController = UITabBarController()
        self?.tabBarViewController = tabBarViewController
        tabBarViewController.delegate = self
        tabBarViewController.viewControllers = [forYouNavigationController, moreNavigationController]

        if navigationController.viewControllers.isEmpty {
          navigationController.viewControllers = [tabBarViewController]
        } else {
          navigationController.pushViewController(tabBarViewController, animated: true)
        }
      }
      .store(in: &cancellables)

    store.scope(state: \.notifications, action: RootReducer.Action.notifications)
      .ifLet { [weak self] store in
        let notificationsViewController = NotificationsViewController(store: store)
        self?.settingsViewController?.show(notificationsViewController, sender: nil)
      }
      .store(in: &cancellables)

    store.scope(state: \.onboarding, action: RootReducer.Action.onboarding)
      .ifLet { [weak self] store in
        let onboardingViewController = OnboardingViewController(store: store)
        self?.onboardingViewController = onboardingViewController
        navigationController.pushViewController(onboardingViewController, animated: true)
      }
      .store(in: &cancellables)

    store.scope(state: \.settings, action: RootReducer.Action.settings)
      .ifLet { [weak self] store in
        let settingsViewController = SettingsViewController(store: store)
        self?.settingsViewController = settingsViewController
        moreViewController.show(settingsViewController, sender: nil)
      }
      .store(in: &cancellables)

    viewStore.send(.didLoad)
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    .portrait
  }
}

extension RootViewController: UITabBarControllerDelegate {
  func tabBarController(_: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    if tabBarViewController?.selectedViewController === viewController, let navigationController = viewController as? UINavigationController {
      switch navigationController.viewControllers.first {
      case let viewController as TodayViewController:
        viewController.scrollToTop()
      case let viewController as MoreViewController:
        viewController.scrollToTop()
      default:
        break
      }
    }

    return true
  }
}
