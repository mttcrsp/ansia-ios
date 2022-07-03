import DesignSystem
import UIKit

public final class LoadingViewController: UIViewController {
  private let activityIndicatorView = UIActivityIndicatorView()

  override public func viewDidLoad() {
    super.viewDidLoad()
    activityIndicatorView.startAnimating()
    view.addSubview(activityIndicatorView)
    view.backgroundColor = DesignSystemAsset.background.color
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    activityIndicatorView.sizeToFit()
    activityIndicatorView.center.x = view.bounds.midX
    activityIndicatorView.center.y = view.bounds.midY
  }
}
