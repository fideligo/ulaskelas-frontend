import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    FirebaseApp.configure()

    // Required when firebase_messaging and flutter_local_notifications are both
    // present. Without an explicit delegate, iOS discards local notification
    // taps and onDidReceiveNotificationResponse never fires.
    //
    // APNs token forwarding is handled by FlutterFire method swizzling;
    // FirebaseAppDelegateProxyEnabled is intentionally left unset.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
