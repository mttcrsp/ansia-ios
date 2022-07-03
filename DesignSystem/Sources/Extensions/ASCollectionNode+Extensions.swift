import AsyncDisplayKit

public extension ASCollectionNode {
  func deselectSelectedItems() {
    for indexPath in indexPathsForSelectedItems ?? [] {
      deselectItem(at: indexPath, animated: true)
    }
  }
}
