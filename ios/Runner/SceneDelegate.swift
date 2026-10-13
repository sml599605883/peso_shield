import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // 冷启动点通知时，系统只把响应放进 scene 连接参数，
    // userNotificationCenter(_:didReceive:) 不会被回调。
    if let response = connectionOptions.notificationResponse {
      ClientBridgeRegistrar.shared.acceptNotificationPayload(
        response.notification.request.content.userInfo
      )
    }
  }
}
