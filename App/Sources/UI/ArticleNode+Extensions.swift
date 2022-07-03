import Core
import DesignSystem

extension ArticleNode.Configuration {
  init(article: Article, style: Style = .default) {
    self.init(
      description: article.description,
      imageURL: article.imageURL,
      publishedAt: article.publishedAt,
      style: style,
      title: article.title
    )
  }
}
