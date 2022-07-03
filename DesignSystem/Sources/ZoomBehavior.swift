import UIKit

public final class ZoomBehavior: NSObject {
  private var pan: UIPanGestureRecognizer?
  private var pinch: UIPinchGestureRecognizer?
  private var backdropView: UIView?
  private var snapshotView: UIView?
  private var view: UIView?

  public func attach(to view: UIView) {
    let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
    let pan = UIPanGestureRecognizer(target: nil, action: nil)
    view.addGestureRecognizer(pinch)
    view.addGestureRecognizer(pan)
    view.isUserInteractionEnabled = true
    self.pinch = pinch
    self.pan = pan
    self.view = view
    for recognizer in [pan, pinch] {
      recognizer.delegate = self
    }
  }

  @objc private func pinched() {
    guard let pan, let pinch, let view, let window = view.window else { return }

    switch pinch.state {
    case .began:
      guard let snapshotView = view.snapshotView(afterScreenUpdates: true) else { return }
      snapshotView.frame = view.convert(view.bounds, to: window)
      snapshotView.isUserInteractionEnabled = false
      self.snapshotView = snapshotView

      let backdropView = UIView()
      backdropView.alpha = 0
      backdropView.backgroundColor = .black
      backdropView.frame = window.bounds
      self.backdropView = backdropView

      view.isHidden = true
      window.addSubview(backdropView)
      window.addSubview(snapshotView)
    case .changed:
      let translation = pan.translation(in: window)
      let scale = max(1, pinch.scale)
      backdropView?.alpha = scale / 5.5
      snapshotView?.transform = .identity
        .translatedBy(x: translation.x, y: translation.y)
        .scaledBy(x: scale, y: scale)
    case _:
      let animatorParams = UISpringTimingParameters()
      let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: animatorParams)
      animator.addAnimations { [weak self] in
        self?.backdropView?.alpha = 0
        self?.snapshotView?.transform = .identity
      }
      animator.addCompletion { [weak self] _ in
        self?.view?.isHidden = false
        self?.backdropView?.removeFromSuperview()
        self?.snapshotView?.removeFromSuperview()
        self?.backdropView = nil
        self?.snapshotView = nil
      }
      animator.startAnimation()
    }
  }
}

extension ZoomBehavior: UIGestureRecognizerDelegate {
  public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
    true
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    switch gestureRecognizer {
    case pinch where otherGestureRecognizer.view is UIScrollView:
      return false
    case pan where otherGestureRecognizer.view is UIScrollView:
      return true
    default:
      return true
    }
  }
}
