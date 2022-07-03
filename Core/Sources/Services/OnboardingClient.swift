import Foundation

public struct OnboardingClient {
  public var didCompleteOnboarding: () -> Bool
  public var didCompleteRegionOnboarding: () -> Bool
  public var didCompleteVideoOnboarding: () -> Bool
  public var didWatchVideo: () -> Bool

  public var setDidCompleteOnboarding: () -> Void
  public var setDidCompleteRegionOnboarding: () -> Void
  public var setDidCompleteVideoOnboarding: () -> Void
  public var setDidWatchVideo: () -> Void

  public init(didCompleteOnboarding: @escaping () -> Bool, didCompleteRegionOnboarding: @escaping () -> Bool, didCompleteVideoOnboarding: @escaping () -> Bool, didWatchVideo: @escaping () -> Bool, setDidCompleteOnboarding: @escaping () -> Void, setDidCompleteRegionOnboarding: @escaping () -> Void, setDidCompleteVideoOnboarding: @escaping () -> Void, setDidWatchVideo: @escaping () -> Void) {
    self.didCompleteOnboarding = didCompleteOnboarding
    self.didCompleteRegionOnboarding = didCompleteRegionOnboarding
    self.didCompleteVideoOnboarding = didCompleteVideoOnboarding
    self.didWatchVideo = didWatchVideo
    self.setDidCompleteOnboarding = setDidCompleteOnboarding
    self.setDidCompleteRegionOnboarding = setDidCompleteRegionOnboarding
    self.setDidCompleteVideoOnboarding = setDidCompleteVideoOnboarding
    self.setDidWatchVideo = setDidWatchVideo
  }
}

public extension OnboardingClient {
  init(userDefaults: UserDefaults) {
    let onboardingKey = "com.mttcrsp.ansia.onboarding.didCompleteOnboardingKey"
    didCompleteOnboarding = { userDefaults.bool(forKey: onboardingKey) }
    setDidCompleteOnboarding = { userDefaults.set(true, forKey: onboardingKey) }

    let regionOnboardingKey = "com.mttcrsp.ansia.onboarding.didCompleteRegionOnboardingKey"
    didCompleteRegionOnboarding = { userDefaults.bool(forKey: regionOnboardingKey) }
    setDidCompleteRegionOnboarding = { userDefaults.set(true, forKey: regionOnboardingKey) }

    let videoOnboardingKey = "com.mttcrsp.ansia.onboarding.didCompleteVideoOnboardingKey"
    didCompleteVideoOnboarding = { userDefaults.bool(forKey: videoOnboardingKey) }
    setDidCompleteVideoOnboarding = { userDefaults.set(true, forKey: videoOnboardingKey) }

    let watchVideoKey = "com.mttcrsp.ansia.onboarding.didWatchVideoKey"
    didWatchVideo = { userDefaults.bool(forKey: watchVideoKey) }
    setDidWatchVideo = { userDefaults.set(true, forKey: watchVideoKey) }
  }
}
