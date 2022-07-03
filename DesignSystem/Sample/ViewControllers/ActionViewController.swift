import AsyncDisplayKit
import DesignSystem

final class ActionViewController: ASDKViewController<ActionableNode> {
  override init() {
    let actionNode = ButtonNode(configuration: .primary)
    actionNode.setTitle("Action", for: .normal)

    let tableNode = ASTableNode()
    super.init(node: .init(contentNode: tableNode, actionsNode: actionNode))
    tableNode.dataSource = self
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension ActionViewController: ASTableDataSource {
  func tableNode(_: ASTableNode, numberOfRowsInSection _: Int) -> Int {
    100
  }

  func tableNode(_: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    {
      let node = ASTextCellNode()
      node.text = indexPath.description
      return node
    }
  }
}
