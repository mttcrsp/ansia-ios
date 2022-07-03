import AsyncDisplayKit

public class CellNode: ASCellNode {
  override public var isHighlighted: Bool {
    didSet { didChangeFocus() }
  }

  override public var isSelected: Bool {
    didSet { didChangeFocus() }
  }

  private func didChangeFocus() {
    alpha = isHighlighted || isSelected ? 0.6 : 1
  }
}
