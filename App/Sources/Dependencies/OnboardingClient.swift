import ComposableArchitecture
import Core

extension OnboardingClient: DependencyKey {
  public static let liveValue = OnboardingClient(
    userDefaults: .standard
  )

  #if DEBUG
  public static let testValue = OnboardingClient(
    didCompleteOnboarding: { false },
    didCompleteRegionOnboarding: { false },
    didCompleteVideoOnboarding: { false },
    didWatchVideo: { false },
    setDidCompleteOnboarding: {},
    setDidCompleteRegionOnboarding: {},
    setDidCompleteVideoOnboarding: {},
    setDidWatchVideo: {}
  )
  #endif
}

extension DependencyValues {
  var onboardingClient: OnboardingClient {
    get { self[OnboardingClient.self] }
    set { self[OnboardingClient.self] = newValue }
  }
}
