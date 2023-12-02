import AsyncDisplayKit

public final class PublishedAtNode: ASTextNode {
  public struct Configuration {
    public let publishedAt: Date
    public init(publishedAt: Date) {
      self.publishedAt = publishedAt
    }
  }

  private var timer: Timer?

  public let configuration: Configuration

  public init(configuration: Configuration) {
    self.configuration = configuration
    super.init()
  }

  deinit {
    timer?.invalidate()
    timer = nil
  }

  override public func didEnterVisibleState() {
    super.didEnterVisibleState()
    attributedText = publishedAtString
    timer = .scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
      self?.attributedText = self?.publishedAtString
    }
  }

  override public func didExitVisibleState() {
    super.didExitVisibleState()
    timer?.invalidate()
    timer = nil
  }

  var publishedAtString: NSAttributedString? {
    PublishedAtFormatter().attributedString(for: configuration.publishedAt)
  }
}
