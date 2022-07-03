import UIKit

open class CrossDissolveViewController: UIViewController {
  public private(set) weak var contentViewController: UIViewController?

  open func setContentViewController(_ contentViewController: UIViewController, animated: Bool, completion externalCompletion: (() -> Void)? = nil) {
    let oldViewController = self.contentViewController
    let newViewController = contentViewController

    guard oldViewController !== newViewController else { return }

    addChild(newViewController)
    view.addSubview(newViewController.view)
    newViewController.view.frame = view.bounds
    newViewController.view.alpha = 0
    oldViewController?.willMove(toParent: nil)

    let animations: () -> Void = {
      newViewController.view.alpha = 1
      oldViewController?.view.alpha = 0
    }

    let completion: (Bool) -> Void = { _ in
      newViewController.view.alpha = 1
      newViewController.didMove(toParent: self)
      oldViewController?.view.removeFromSuperview()
      oldViewController?.removeFromParent()
      externalCompletion?()
    }

    if animated {
      UIView.animate(
        withDuration: CATransaction.animationDuration(),
        delay: 0,
        animations: animations,
        completion: completion
      )
    } else {
      UIView.performWithoutAnimation(animations)
      completion(true)
    }

    self.contentViewController = contentViewController
  }

  override open func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    contentViewController?.view.frame = view.bounds
  }
}
