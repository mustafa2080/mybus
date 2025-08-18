import Flutter
import UIKit
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()

    // Set up notification center delegate
    UNUserNotificationCenter.current().delegate = self

    // Request notification permissions with all options
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional, .criticalAlert]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if granted {
          print("✅ iOS Notification permission granted")
        } else {
          print("❌ iOS Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
        }
      }
    )

    // Register for remote notifications
    application.registerForRemoteNotifications()

    // Configure for background processing
    if #available(iOS 13.0, *) {
      application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle successful registration for remote notifications
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ iOS Device registered for remote notifications")
    // Pass device token to Firebase
    Messaging.messaging().apnsToken = deviceToken
  }

  // Handle failed registration for remote notifications
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ iOS Failed to register for remote notifications: \(error.localizedDescription)")
  }

  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("📱 iOS Notification tapped: \(response.notification.request.content.userInfo)")
    completionHandler()
  }
}
