import AdSupport
import AppTrackingTransparency
import Flutter
import StoreKit
import TDMobRisk
import UIKit

/// The sole native-to-Flutter entry point for Runner capabilities.
final class ClientBridgeRegistrar: NSObject {
  static let shared = ClientBridgeRegistrar()

  private static let channelName = "peso_shield/client_bridge"
  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionAppKey = "1dc25522f2adc77f5347816c0f7fa31b"
  /// TrustDecision invokes the success block with a non-zero code for some
  /// failures (for example, capture succeeded but the result was rejected).
  /// Only a code of 200 means the liveness actually completed, regardless of
  /// which block fires.
  private static let livenessSuccessCode = 200
  private var hasActivatedTrustDecision = false
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()

  private override init() {
    super.init()
  }

  func register(with controller: FlutterViewController?) {
    guard let controller else { return }
    register(with: controller.binaryMessenger)
  }

  func register(with binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      // Try reporting methods first
      if self.handleReportMethod(call, result: result) {
        return
      }
      
      // Fallback to other methods
      switch call.method {
      case "showTrustDecisionLiveness":
        self.showTrustDecisionLiveness(call.arguments, result: result)
      case "registerForRemoteNotifications":
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      case "getTrackingStatus":
        result(self.currentTrackingStatus())
      case "getPushToken":
        result(self.pushToken)
      case "requestAppReview":
        self.requestAppReview(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Register event channel for reporting
    registerReportingMethods(with: binaryMessenger)
  }

  private func requestAppReview(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if #available(iOS 14.0, *) {
        guard let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive })
        else {
          result(nil)
          return
        }
        SKStoreReviewController.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview()
      }
      result(nil)
    }
  }

  /// Activates device-risk collection at application launch.
  func activateTrustDecision() {
    guard !hasActivatedTrustDecision else { return }
    hasActivatedTrustDecision = true
    trustDecisionManager?.pointee.initWithOptions([
      "partner": trustDecisionPartnerCode,
      "appKey": trustDecisionAppKey,
      "country": "sg",
      "language": "en",
      "showReadyPage": false,
      "runningTasks": false,
      "readPhonoe": false,
      "installPackageList": false,
      "playAudio": true
    ])
  }

  private func showTrustDecisionLiveness(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
    activateTrustDecision()
    guard let license = arguments as? String, !license.isEmpty,
          let viewController = topViewController() else {
      result([
        "success": false,
        "code": -1,
        "message": "Liveness verification is unavailable.",
        "image": "",
        "sequence_id": "",
        "liveness_id": "",
        "raw": [:]
      ])
      return
    }

    trustDecisionManager?.pointee.showLivenessWithShowStyle(
      viewController,
      license,
      TDLivenessShowStylePresent,
      { payload in result(self.livenessResult(payload: payload)) },
      { payload in result(self.livenessResult(payload: payload)) }
    )
  }

  private func livenessResult(payload: [AnyHashable: Any]?) -> [String: Any] {
    let raw = (payload as? [String: Any]) ?? [:]
    let code: Int
    if let number = raw["code"] as? NSNumber {
      code = number.intValue
    } else if let string = raw["code"] as? String, let parsed = Int(string) {
      code = parsed
    } else {
      code = -1
    }
    let success = code == Self.livenessSuccessCode
    return [
      "success": success,
      "code": code,
      "message": raw["message"] as? String ?? "",
      "image": raw["image"] as? String ?? "",
      "sequence_id": raw["sequence_id"] as? String ?? "",
      "liveness_id": raw["liveness_id"] as? String ?? "",
      "raw": raw
    ]
  }

  private func topViewController(
    from viewController: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }
}
