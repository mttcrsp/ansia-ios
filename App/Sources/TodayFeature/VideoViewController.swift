import AVKit
import Core

final class VideoViewController: AVPlayerViewController {
  var onDismiss: () -> Void = {}
  var onDidPlayToEndTime: () -> Void = {}

  private var observer: NSObjectProtocol?

  init(video: Video) {
    super.init(nibName: nil, bundle: nil)
    delegate = self
    player = AVPlayer(url: video.videoURL)
    player?.play()
    updatesNowPlayingInfoCenter = false
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      self?.onDidPlayToEndTime()
    }
  }

  override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    .landscapeRight
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    .landscape
  }
}

extension VideoViewController: AVPlayerViewControllerDelegate {
  func playerViewController(_: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: nil) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.onDismiss() // hold strong reference to prevent deallocation after dismissal
      }
    }
  }
}
