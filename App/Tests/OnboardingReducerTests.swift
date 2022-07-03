@testable
import App
import ComposableArchitecture
import Core
import XCTest

@MainActor
final class OnboardingReducerTests: XCTestCase {
  func testDidLoad() async {
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)

    let store = TestStore(initialState: .init(), reducer: OnboardingReducer())

    var updateFeeds: [Feed]?
    store.dependencies.persistenceClient.updateFeeds = { value in
      updateFeeds = value
    }
    store.dependencies.networkClient.getFeeds = {
      [feed1]
    }

    var collection: Feed.Collection?
    let observedFeeds = AsyncThrowingStream<[Feed], Error>.streamWithContinuation()
    store.dependencies.persistenceClient.observeFeedsByCollection = { value in
      collection = value
      return observedFeeds.stream
    }

    let task = await store.send(.didLoad)

    observedFeeds.continuation.yield([feed2])
    await store.receive(.sectionsChanged([feed2])) { state in
      state.sections = [feed2]
    }

    await store.send(.didUnload).finish()
    await task.finish()

    XCTAssertEqual(updateFeeds, [feed1])
    XCTAssertEqual(collection, .main)
  }

  func testDidLoadUpdateFailed() async {
    let store = TestStore(initialState: .init(), reducer: OnboardingReducer())
    store.dependencies.networkClient.getFeeds = {
      throw URLError(.notConnectedToInternet)
    }

    await store.send(.didLoad).finish()
    await store.receive(.sectionsLoadingFailed) { state in
      state.didFail = true
    }
  }

  func testSectionsLoadingFailed() async {
    let feed = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let store = TestStore(initialState: .init(didFail: true), reducer: OnboardingReducer())

    var updateFeeds: [Feed]?
    store.dependencies.persistenceClient.updateFeeds = { value in
      updateFeeds = value
    }
    store.dependencies.networkClient.getFeeds = {
      [feed]
    }

    await store.send(.sectionsLoadingRetryTapped) { state in
      state.didFail = false
    }.finish()

    XCTAssertEqual(updateFeeds, [feed])
  }

  func testMinimumSectionsDismissTapped() async {
    let state = OnboardingReducer.State(minimumSectionsAlert: .init(title: TextState("title"), buttons: []))
    let store = TestStore(initialState: state, reducer: OnboardingReducer())
    await store.send(.minimumSectionsDismissTapped) { state in
      state.minimumSectionsAlert = nil
    }.finish()
  }

  func testSectionsConfirmTapped() async {
    let feed1 = Feed(slug: "1", title: "1", collection: "1", emoji: "1", weight: 1)
    let feed2 = Feed(slug: "2", title: "2", collection: "2", emoji: "2", weight: 2)
    let feed3 = Feed(slug: "3", title: "3", collection: "3", emoji: "3", weight: 3)
    let store = TestStore(initialState: .init(), reducer: OnboardingReducer())

    var sections: [Feed.Slug]?
    store.dependencies.favoritesClient.setFavoriteSections = { value in
      sections = value
    }

    var didCompleteOnboarding = false
    store.dependencies.onboardingClient.setDidCompleteOnboarding = {
      didCompleteOnboarding = true
    }

    await store.send(.sectionsConfirmTapped([feed1, feed2, feed3])).finish()
    await store.receive(.didComplete)

    XCTAssertEqual(didCompleteOnboarding, true)
    XCTAssertEqual(sections, [feed1, feed2, feed3].map(\.slug))
  }

  func testSectionsConfirmTappedInvalid() async {
    let store = TestStore(initialState: .init(), reducer: OnboardingReducer())
    await store.send(.sectionsConfirmTapped([])) { state in
      state.minimumSectionsAlert = .init(
        title: TextState("Seleziona almeno 3 sezioni"),
        buttons: [
          .default(
            TextState("Ok"),
            action: .send(.minimumSectionsDismissTapped)
          ),
        ]
      )
    }.finish()
  }
}
