import UIKit

var app: UIApplication.Type = UIApplication.self
var appDelegate: UIApplicationDelegate.Type = ApplicationDelegate.self

#if DEBUG
private final class TestApp: UIApplication {}
private final class TestAppDelegate: NSObject, UIApplicationDelegate {}
if NSClassFromString("XCTest") != nil {
  app = TestApp.self
  appDelegate = TestAppDelegate.self
}
#endif

UIApplicationMain(
  CommandLine.argc,
  CommandLine.unsafeArgv,
  NSStringFromClass(app),
  NSStringFromClass(appDelegate)
)
