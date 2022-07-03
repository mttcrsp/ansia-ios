import ProjectDescription

let swiftFormat = TargetScript.post(
  script: "./run-swiftformat",
  name: "SwiftFormat"
)

let mockolo = TargetScript.pre(
  script: "./run-mockolo",
  name: "Mockolo"
)

let bundleId = "com.mttcrsp.ansia"

let app = Target(
  name: "Ansia",
  platform: .iOS,
  product: .app,
  bundleId: bundleId,
  deploymentTarget: .iOS(targetVersion: "15.0", devices: [.iphone, .ipad]),
  infoPlist: .extendingDefault(with: [
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "1.0.0",
    "ITSAppUsesNonExemptEncryption": false,
    "UILaunchStoryboardName": "LaunchScreen",
    "UIApplicationSceneManifest": [
      "UISceneConfigurations": [
        "UIWindowSceneSessionRoleApplication": [
          [
            "UISceneConfigurationName": "Default Configuration",
            "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
          ],
        ],
      ],
    ],
  ]),
  sources: ["Sources/**/*"],
  resources: ["Resources/**/*"],
  scripts: [swiftFormat]
)

let appTests = Target(
  name: "Tests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(bundleId).tests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["Tests/**", "Mocks/**"],
  resources: ["Tests/Resources/**/*"],
  scripts: [mockolo, swiftFormat],
  dependencies: [.target(name: app.name)]
)

let project = Project(
  name: "Ansia",
  organizationName: "Matteo Crespi",
  settings: Settings.settings(base: ["SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES"]),
  targets: [app, appTests]
)
