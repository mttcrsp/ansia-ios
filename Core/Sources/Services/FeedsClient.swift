import Foundation

public struct FeedsClient {
  public var loadArticles: ([Feed.Slug]) async throws -> Void
  public init(loadArticles: @escaping ([Feed.Slug]) -> Void) {
    self.loadArticles = loadArticles
  }
}

public extension FeedsClient {
  private struct GroupResult {
    let slug: Feed.Slug
    let articles: [Article]
  }

  init(networkService: NetworkService, persistenceService: PersistenceService) {
    loadArticles = { slugs in
      try await withThrowingTaskGroup(of: GroupResult.self) { group in
        for slug in slugs {
          group.addTask {
            let articlesRequest = ArticlesByFeedRequest(slug: slug)
            let articlesResponse = try await networkService.perform(articlesRequest)
            return GroupResult(slug: slug, articles: articlesResponse.articles)
          }
        }

        var feeds: [Feed.Slug: [Article]] = [:]
        for try await result in group {
          feeds[result.slug] = result.articles
        }

        let articlesWrite = UpdateFeedsArticles(feeds: feeds)
        try await persistenceService.perform(articlesWrite)
      }
    }
  }
}
