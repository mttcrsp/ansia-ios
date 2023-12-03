public struct SetupClient {
  public var perform: () async throws -> Void
  public init(perform: @escaping () -> Void) {
    self.perform = perform
  }
}

public extension SetupClient {
  private enum UnexpectedError: Error {
    case groupNotFound
  }

  init(fileManager: FileManagerProtocol, networkService: NetworkService, persistenceService: PersistenceService) {
    perform = {
      guard let applicationDatabaseURL = fileManager
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.mttcrsp.ansia")?
        .appendingPathComponent("db")
        .appendingPathExtension("sqlite")
      else { throw UnexpectedError.groupNotFound }

      try persistenceService.load(at: applicationDatabaseURL.path)

      let feedsRead = GetFeedsByCollection(collection: .main)
      let feeds = try persistenceService.performSync(feedsRead)
      guard feeds.isEmpty else { return }

      let feedsRequest = FeedsRequest()
      let feedsResponse = try await networkService.perform(feedsRequest)
      let feedsWrite = UpdateFeeds(feeds: feedsResponse.feeds)
      try await persistenceService.perform(feedsWrite)
    }
  }
}
