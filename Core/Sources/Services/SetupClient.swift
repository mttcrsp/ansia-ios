public struct SetupClient {
  public var perform: () async throws -> Void
  public init(perform: @escaping () -> Void) {
    self.perform = perform
  }
}

public extension SetupClient {
  init(fileManager: FileManagerProtocol, networkService: NetworkService, persistenceService: PersistenceService) {
    perform = {
      let applicationSupportURL = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      let applicationDatabaseURL = applicationSupportURL
        .appendingPathComponent("db")
        .appendingPathExtension("sqlite")
      try persistenceService.load(at: applicationDatabaseURL.path)

      let feedsRead = GetFeedsByCollection(collection: .main)
      let feeds = try persistenceService.performSync(feedsRead)
      guard feeds.isEmpty else {
        return
      }

      let feedsRequest = FeedsRequest()
      let feedsResponse = try await networkService.perform(feedsRequest)
      let feedsWrite = UpdateFeeds(feeds: feedsResponse.feeds)
      try await persistenceService.perform(feedsWrite)
    }
  }
}
