import Flutter
import UIKit
import CFNetwork

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ClientBridgeRegistrar.shared.activateTrustDecision()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
