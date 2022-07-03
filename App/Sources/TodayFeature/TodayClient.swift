import ComposableArchitecture
import Core

struct TodayGroups: Equatable {
  var home: TodayGroup?
  var region: TodayGroup?
  var sections: [TodayGroup] = []
}

struct TodayGroup: Equatable {
  let articles: [Article]
  let feed: Feed?
  init(feed: Feed? = nil, articles: [Article]) {
    self.articles = articles
    self.feed = feed
  }
}

struct TodayClient {
  let favoritesClient: FavoritesClient
  let persistenceClient: PersistenceClient

  func getGroups() async throws -> TodayGroups {
    async let home = getSection(.home, limit: 4)
    async let region = getRegion()
    async let sections = getSections()
    return try await TodayGroups(home: home, region: region, sections: sections)
  }

  func getRegion() async throws -> TodayGroup? {
    if let slug = favoritesClient.favoriteRegion() {
      return try await getSection(slug, limit: 6)
    } else {
      return nil
    }
  }

  func getSection(_ slug: Feed.Slug, limit: Int) async throws -> TodayGroup {
    async let feed = persistenceClient.getFeed(slug)
    async let articles = persistenceClient.getArticles(slug, limit)
    return try await TodayGroup(feed: feed, articles: articles)
  }

  func getSections() async throws -> [TodayGroup] {
    let sections = favoritesClient.favoriteSections()
    return try await withThrowingTaskGroup(of: TodayGroup.self) { group in
      for slug in sections {
        group.addTask {
          try await getSection(slug, limit: 4)
        }
      }

      var groups: [TodayGroup] = []
      for try await section in group {
        groups.append(section)
      }

      return groups
    }
  }
}
