import Flutter
import UIKit
import CFNetwork
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ClientBridgeRegistrar.shared.activateTrustDecision()
    UNUserNotificationCenter.current().delegate = self
    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    if let payload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      ClientBridgeRegistrar.shared.acceptNotificationPayload(payload)
    }
    return launched
  }
  
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    ClientBridgeRegistrar.shared.updatePushToken(token)
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }
  
  /// 前台收到通知：带跳转地址时不展示系统横幅，直接交给 App 内路由，
  /// 其余通知保持系统默认展示。
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let routed = ClientBridgeRegistrar.shared.acceptNotificationPayload(
      notification.request.content.userInfo
    )
    completionHandler(routed ? [] : [.banner, .badge, .sound])
  }

  /// 用户点击通知（App 已运行或在后台）。
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    ClientBridgeRegistrar.shared.acceptNotificationPayload(
      response.notification.request.content.userInfo
    )
    completionHandler()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    ClientBridgeRegistrar.shared.publishTrackingStatus()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register ClientBridgeRegistrar for native interactions
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "PesoShieldClientBridge"
    ) else {
      return
    }
    ClientBridgeRegistrar.shared.register(with: registrar.messenger())

    // Register capture proxy channel
    let channel = FlutterMethodChannel(
      name: "peso_shield/capture_proxy",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "getSystemProxy" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
          as? [String: Any],
        (settings[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue == true,
        let host = settings[kCFNetworkProxiesHTTPProxy as String] as? String,
        let port = (settings[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue,
        !host.isEmpty,
        port > 0
      else {
        result(nil as Any?)
        return
      }
      result(["host": host, "port": port])
    }
  }
}
