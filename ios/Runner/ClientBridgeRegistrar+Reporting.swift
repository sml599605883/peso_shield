import AdSupport
import AppTrackingTransparency
import CoreLocation
import Darwin
import Flutter
import Security
import UIKit

extension ClientBridgeRegistrar: FlutterStreamHandler, CLLocationManagerDelegate {
  private static let eventChannelName = "peso_shield/client_events"
  private static let vendorIdentifierAccount = "peso_shield_device_identifier"
  
  private var eventSink: FlutterEventSink? {
    get { objc_getAssociatedObject(self, &AssociatedKeys.eventSink) as? FlutterEventSink }
    set { objc_setAssociatedObject(self, &AssociatedKeys.eventSink, newValue, .OBJC_ASSOCIATION_RETAIN) }
  }
  
  var pushToken: String {
    get { (objc_getAssociatedObject(self, &AssociatedKeys.pushToken) as? String) ?? "" }
    set { objc_setAssociatedObject(self, &AssociatedKeys.pushToken, newValue, .OBJC_ASSOCIATION_COPY) }
  }
  
  /// Flutter 尚未开始监听事件通道时到达的通知路由，按到达顺序缓存。
  var pendingNotificationRoutes: [String] {
    get {
      (objc_getAssociatedObject(self, &AssociatedKeys.pendingNotificationRoutes) as? [String]) ?? []
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.pendingNotificationRoutes,
        newValue,
        .OBJC_ASSOCIATION_RETAIN
      )
    }
  }

  private var deviceSnapshotCollector: PesoDeviceSnapshotCollector {
    get {
      if let collector = objc_getAssociatedObject(self, &AssociatedKeys.collector) as? PesoDeviceSnapshotCollector {
        return collector
      }
      let collector = PesoDeviceSnapshotCollector()
      objc_setAssociatedObject(self, &AssociatedKeys.collector, collector, .OBJC_ASSOCIATION_RETAIN)
      return collector
    }
  }
  
  private var locationManager: CLLocationManager? {
    get { objc_getAssociatedObject(self, &AssociatedKeys.locationManager) as? CLLocationManager }
    set { objc_setAssociatedObject(self, &AssociatedKeys.locationManager, newValue, .OBJC_ASSOCIATION_RETAIN) }
  }
  
  private var locationResult: FlutterResult? {
    get { objc_getAssociatedObject(self, &AssociatedKeys.locationResult) as? FlutterResult }
    set { objc_setAssociatedObject(self, &AssociatedKeys.locationResult, newValue, .OBJC_ASSOCIATION_COPY) }
  }
  
  private var locationPermissionManager: CLLocationManager? {
    get { objc_getAssociatedObject(self, &AssociatedKeys.locationPermissionManager) as? CLLocationManager }
    set { objc_setAssociatedObject(self, &AssociatedKeys.locationPermissionManager, newValue, .OBJC_ASSOCIATION_RETAIN) }
  }
  
  private var locationPermissionResult: FlutterResult? {
    get { objc_getAssociatedObject(self, &AssociatedKeys.locationPermissionResult) as? FlutterResult }
    set { objc_setAssociatedObject(self, &AssociatedKeys.locationPermissionResult, newValue, .OBJC_ASSOCIATION_COPY) }
  }
  
  private struct AssociatedKeys {
    static var eventSink: UInt8 = 0
    static var pushToken: UInt8 = 0
    static var pendingNotificationRoutes: UInt8 = 0
    static var collector: UInt8 = 0
    static var locationManager: UInt8 = 0
    static var locationResult: UInt8 = 0
    static var locationPermissionManager: UInt8 = 0
    static var locationPermissionResult: UInt8 = 0
  }
  
  func registerReportingMethods(with binaryMessenger: FlutterBinaryMessenger) {
    let eventChannel = FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: binaryMessenger
    )
    eventChannel.setStreamHandler(self)
  }
  
  func handleReportMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
    switch call.method {
    case "getReportLocation":
      getReportLocation(result)
      return true
    case "requestLocationPermission":
      requestLocationPermission(result)
      return true
    case "getReportDeviceSnapshot":
      getReportDeviceSnapshot(result)
      return true
    case "getStableDeviceId":
      result(stableVendorIdentifier())
      return true
    case "getPushToken":
      result(pushToken)
      return true
    case "registerForRemoteNotifications":
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
        result(nil)
      }
      return true
    case "getTrackingStatus":
      result(currentTrackingStatus())
      return true
    default:
      return false
    }
  }
  
  // MARK: - FlutterStreamHandler
  
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    if !pushToken.isEmpty {
      events(["type": "push_token", "token": pushToken])
    }
    while !pendingNotificationRoutes.isEmpty {
      let route = pendingNotificationRoutes.removeFirst()
      events(["type": "push_route", "url": route])
    }
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
  
  func updatePushToken(_ token: String) {
    pushToken = token
    guard !token.isEmpty else { return }
    eventSink?(["type": "push_token", "token": token])
  }
  
  // MARK: - Push route

  /// 解析通知点击/冷启动 payload 里的跳转地址。
  ///
  /// 兼容三种下发形式：顶层 `url`、`params.url` 字典、`params` 为 JSON 字符串。
  /// 命中地址时返回 true；此时前台通知不再展示系统横幅，避免和 App 内跳转重复。
  @discardableResult
  func acceptNotificationPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
    guard let route = notificationRoute(from: userInfo) else {
      return false
    }
    guard let eventSink else {
      // Flutter 侧还没开始监听，先缓存，等 onListen 时补发。
      pendingNotificationRoutes.append(route)
      return true
    }
    eventSink(["type": "push_route", "url": route])
    return true
  }

  private func notificationRoute(from userInfo: [AnyHashable: Any]) -> String? {
    if let route = normalizedNotificationRoute(userInfo["url"]) {
      return route
    }
    if let params = userInfo["params"] as? [AnyHashable: Any] {
      return normalizedNotificationRoute(params["url"])
    }
    guard
      let paramsText = userInfo["params"] as? String,
      let paramsData = paramsText.data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: paramsData),
      let params = decoded as? [String: Any]
    else {
      return nil
    }
    return normalizedNotificationRoute(params["url"])
  }

  private func normalizedNotificationRoute(_ value: Any?) -> String? {
    guard let value = value as? String else {
      return nil
    }
    let route = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return route.isEmpty ? nil : route
  }

  func publishTrackingStatus() {
    eventSink?([
      "type": "tracking_status_changed",
      "status": currentTrackingStatus()
    ])
  }
  
  // MARK: - Location
  
  private func getReportLocation(_ result: @escaping FlutterResult) {
    guard locationResult == nil else {
      result(FlutterError(
        code: "location_in_progress",
        message: "A location request is already in progress",
        details: nil
      ))
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result(locationPayload(location: nil, placemark: nil, status: "service_disabled"))
      return
    }

    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager = manager
    locationResult = result
    let status = manager.authorizationStatus
    if status == .notDetermined {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    } else if status == .denied || status == .restricted {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    } else {
      manager.requestLocation()
    }
  }
  
  private func requestLocationPermission(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result("service_disabled")
      return
    }
    let manager = CLLocationManager()
    manager.delegate = self
    if let previousResult = locationPermissionResult {
      locationPermissionResult = nil
      locationPermissionManager = nil
      previousResult("interrupted")
    }
    locationPermissionManager = manager
    locationPermissionResult = result
    let status = manager.authorizationStatus
    guard status == .notDetermined else {
      locationPermissionManager = nil
      locationPermissionResult = nil
      result(locationStatus(status))
      return
    }
    manager.requestWhenInUseAuthorization()
  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager === locationPermissionManager {
      let status = manager.authorizationStatus
      guard status != .notDetermined else { return }
      let result = locationPermissionResult
      locationPermissionResult = nil
      locationPermissionManager = nil
      result?(locationStatus(status))
      return
    }
    guard locationResult != nil else { return }
    let status = manager.authorizationStatus
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      manager.requestLocation()
    } else if status == .denied || status == .restricted {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    }
  }
  
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else {
      finishLocation(locationPayload(
        location: nil,
        placemark: nil,
        status: locationStatus(manager.authorizationStatus)
      ))
      return
    }
    CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
      guard let self else { return }
      self.finishLocation(self.locationPayload(
        location: location,
        placemark: placemarks?.first,
        status: self.locationStatus(manager.authorizationStatus)
      ))
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocation(locationPayload(
      location: nil,
      placemark: nil,
      status: locationStatus(manager.authorizationStatus)
    ))
  }
  
  private func finishLocation(_ payload: [String: Any]) {
    let result = locationResult
    locationResult = nil
    locationManager?.stopUpdatingLocation()
    locationManager = nil
    result?(payload)
  }
  
  private func locationPayload(
    location: CLLocation?,
    placemark: CLPlacemark?,
    status: String
  ) -> [String: Any] {
    return [
      "province": placemark?.administrativeArea ?? "",
      "locality": placemark?.subAdministrativeArea ?? "",
      "fullAddress": fullAddress(from: placemark),
      "countryCode": placemark?.isoCountryCode ?? "",
      "country": placemark?.country ?? "",
      "street": placemark?.thoroughfare ?? "",
      "latitude": location.map { String($0.coordinate.latitude) } ?? "",
      "longitude": location.map { String($0.coordinate.longitude) } ?? "",
      "city": placemark?.locality ?? "",
      "permissionStatus": status
    ]
  }
  
  private func fullAddress(from placemark: CLPlacemark?) -> String {
    guard let placemark else { return "" }
    var parts: [String] = []
    if let country = placemark.country { parts.append(country) }
    if let administrativeArea = placemark.administrativeArea { parts.append(administrativeArea) }
    if let locality = placemark.locality { parts.append(locality) }
    if let thoroughfare = placemark.thoroughfare { parts.append(thoroughfare) }
    if let subThoroughfare = placemark.subThoroughfare { parts.append(subThoroughfare) }
    if let postalCode = placemark.postalCode { parts.append(postalCode) }
    return parts.joined(separator: ", ")
  }
  
  private func locationStatus(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_determined"
    @unknown default: return "not_determined"
    }
  }
  
  // MARK: - Device Snapshot
  
  private func getReportDeviceSnapshot(_ result: @escaping FlutterResult) {
    deviceSnapshotCollector.collect(
      idfv: stableVendorIdentifier(),
      idfa: currentAdvertisingIdentifier(),
      pushToken: pushToken,
      isUsingProxy: isUsingHttpProxy(),
      modelIdentifier: deviceModelName(),
      completion: { snapshot in result(snapshot) }
    )
  }
  
  // MARK: - Tracking
  
  func currentTrackingStatus() -> String {
    switch ATTrackingManager.trackingAuthorizationStatus {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_determined"
    @unknown default: return "not_determined"
    }
  }
  
  // MARK: - Device Info
  
  /// 设备标识：优先返回 Keychain 中持久化的值。
  ///
  /// IDFV 在同一 vendor 的应用被全部卸载后会重新生成，因此卸载重装即会变化。
  /// 首次取得 IDFV 后写入 Keychain（卸载不掉），即可保证重装后标识不变。
  private func stableVendorIdentifier() -> String {
    if let stored = Self.storedVendorIdentifier(), !stored.isEmpty {
      return stored
    }

    let vendorIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    guard !vendorIdentifier.isEmpty else { return "" }

    Self.persistVendorIdentifier(vendorIdentifier)
    return vendorIdentifier
  }

  private static var vendorIdentifierService: String {
    Bundle.main.bundleIdentifier ?? "com.pesoshield.app"
  }

  private static func storedVendorIdentifier() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: vendorIdentifierService,
      kSecAttrAccount as String: vendorIdentifierAccount,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    return value
  }

  private static func persistVendorIdentifier(_ value: String) {
    guard let data = value.data(using: .utf8) else { return }
    let baseQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: vendorIdentifierService,
      kSecAttrAccount as String: vendorIdentifierAccount,
    ]
    SecItemDelete(baseQuery as CFDictionary)

    var query = baseQuery
    query[kSecValueData as String] = data
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    SecItemAdd(query as CFDictionary, nil)
  }

  private func isUsingHttpProxy() -> Bool {
    guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
      as? [String: Any] else { return false }
    return ["HTTPEnable", "HTTPSEnable", "SOCKSEnable", "ProxyAutoConfigEnable"]
      .contains { (settings[$0] as? NSNumber)?.boolValue == true }
  }
  
  private func currentAdvertisingIdentifier() -> String {
    guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
      return ""
    }
    let idfa = ASIdentifierManager.shared().advertisingIdentifier
    return idfa.uuidString == "00000000-0000-0000-0000-000000000000" ? "" : idfa.uuidString
  }
  
  private func deviceModelName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
  }
}
