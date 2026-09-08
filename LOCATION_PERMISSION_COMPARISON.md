# 定位权限实现对比

## 架构对比

### 两个项目的定位权限实现**基本一致**，仅有 1 处细微差异

| 对比项 | dali_cash | peso_shield | 状态 |
|--------|-----------|-------------|------|
| Native 实现 | ✅ | ✅ | **完全一致** |
| Dart 协调器 | ✅ | ✅ | **完全一致** |
| 4 种决策状态 | ✅ | ✅ | **完全一致** |
| 生命周期中断检测 | ✅ | ✅ | **完全一致** |
| 服务开启检测 | ✅ | ✅ | **完全一致** |
| 状态字符串转换 | 细粒度 | 合并 | **1 处差异** |

## 唯一差异：`locationStatus()` 转换方法

### dali_cash（细粒度）
```swift
private func locationStatus(_ status: CLAuthorizationStatus) -> String {
  switch status {
  case .authorizedAlways: return "authorized_always"        // 细分
  case .authorizedWhenInUse: return "authorized_when_in_use" // 细分
  case .denied: return "denied"
  case .restricted: return "restricted"
  case .notDetermined: return "not_determined"
  @unknown default: return "unknown"
  }
}
```

### peso_shield（合并）
```swift
private func locationStatus(_ status: CLAuthorizationStatus) -> String {
  switch status {
  case .authorizedAlways, .authorizedWhenInUse: return "authorized" // 合并
  case .denied: return "denied"
  case .restricted: return "restricted"
  case .notDetermined: return "not_determined"
  @unknown default: return "not_determined"
  }
}
```

### Dart 侧处理（完全一致）

两个项目的 Dart 侧都会将这些状态映射为 `PermissionStatus`：

```dart
Future<PermissionStatus> _requestLocationViaClientBridge(ClientBridge clientBridge) {
  return clientBridge.requestLocationPermission().then((status) {
    return switch (status) {
      'authorized' ||
      'authorized_always' ||          // dali_cash 会返回这个
      'authorized_when_in_use' =>     // dali_cash 会返回这个
        PermissionStatus.granted,
      'limited' => PermissionStatus.limited,
      'restricted' => PermissionStatus.restricted,
      'permanently_denied' => PermissionStatus.permanentlyDenied,
      _ => PermissionStatus.denied,
    };
  });
}
```

**实际影响：** 无，因为：
1. peso_shield 的 Dart 侧已经兼容了 dali_cash 的细粒度返回值
2. 两种授权状态在业务逻辑中都被视为 `granted`
3. peso_shield 只请求 `whenInUse` 权限，不会出现 `always`

## 详细对比

### 1. Native 层实现（iOS）

#### `requestLocationPermission()` 方法
**两个项目实现完全相同：**
```swift
private func requestLocationPermission(_ result: @escaping FlutterResult) {
  // 1. 检查定位服务是否开启
  guard CLLocationManager.locationServicesEnabled() else {
    result("service_disabled")
    return
  }
  
  // 2. 创建 CLLocationManager
  let manager = CLLocationManager()
  manager.delegate = self
  
  // 3. 中断之前的请求（防止多次调用）
  if let previousResult = locationPermissionResult {
    locationPermissionResult = nil
    locationPermissionManager = nil
    previousResult("interrupted")
  }
  
  // 4. 保存当前请求
  locationPermissionManager = manager
  locationPermissionResult = result
  
  // 5. 检查当前状态
  let status = manager.authorizationStatus
  guard status == .notDetermined else {
    // 如果已经决定，直接返回
    locationPermissionManager = nil
    locationPermissionResult = nil
    result(locationStatus(status))
    return
  }
  
  // 6. 请求权限
  manager.requestWhenInUseAuthorization()
}
```

**差异：** 无

#### `locationManagerDidChangeAuthorization()` 回调
**两个项目逻辑完全相同：**
```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
  // 1. 检查是否是权限请求的 manager
  if manager === locationPermissionManager {
    let status = manager.authorizationStatus
    guard status != .notDetermined else { return }
    
    // 2. 返回结果
    let result = locationPermissionResult
    locationPermissionResult = nil
    locationPermissionManager = nil
    result?(locationStatus(status))
    return
  }
  
  // 3. 处理定位获取的情况（另一个 manager）
  guard locationResult != nil else { return }
  let status = manager.authorizationStatus
  if status == .authorizedAlways || status == .authorizedWhenInUse {
    manager.requestLocation()
  } else if status == .denied || status == .restricted {
    finishLocation(locationPayload(...))
  }
}
```

**差异：** 无

### 2. Dart 层协调器（PermissionCoordinator）

#### `requestCertificationLocation()` 方法
**两个项目实现完全相同：**
```dart
Future<CertificationLocationDecision> _requestCertificationLocation() async {
  try {
    // 1. 检查定位服务是否开启
    final serviceStatus = await _locationServiceStatusProvider();
    if (serviceStatus != ServiceStatus.enabled) {
      return CertificationLocationDecision.serviceDisabled;
    }

    // 2. 检查当前权限状态
    final status = await _locationPermissionStatusProvider();
    if (_isGranted(status)) {
      return CertificationLocationDecision.granted;
    }
    if (_requiresSettings(status)) {
      return CertificationLocationDecision.settingsRequired;
    }

    // 3. 请求权限（带生命周期中断检测）
    final requestedStatus = await _requestLocationPermissionUntilInterrupted();
    if (requestedStatus == null) {
      return CertificationLocationDecision.denied;
    }
    if (_isGranted(requestedStatus)) {
      return CertificationLocationDecision.granted;
    }
    if (_requiresSettings(requestedStatus)) {
      return CertificationLocationDecision.settingsRequired;
    }
    return CertificationLocationDecision.settingsRequired;
  } catch (_) {
    return CertificationLocationDecision.denied;
  }
}
```

**差异：** 无

#### 生命周期中断检测
**两个项目实现完全相同：**
```dart
Future<PermissionStatus?> _requestLocationPermissionUntilInterrupted() async {
  final interrupted = Completer<PermissionStatus?>();
  
  // 监听 app 生命周期变化
  final observer = _LocationPermissionLifecycleObserver(() {
    if (!interrupted.isCompleted) {
      interrupted.complete();  // app 进入后台时中断
    }
  });
  
  WidgetsBinding.instance.addObserver(observer);
  try {
    // 竞速：权限请求 vs 生命周期中断
    return await Future.any<PermissionStatus?>([
      _locationPermissionRequester().then<PermissionStatus?>((status) => status),
      interrupted.future,
    ]);
  } finally {
    WidgetsBinding.instance.removeObserver(observer);
  }
}
```

**差异：** 无

### 3. 决策状态枚举

**两个项目定义完全相同：**
```dart
enum CertificationLocationDecision {
  granted,           // 已授权
  denied,            // 拒绝
  settingsRequired,  // 需要去设置（永久拒绝或受限）
  serviceDisabled,   // 定位服务未开启
}
```

**差异：** 无

## 总结

### 核心功能对比

| 功能点 | dali_cash | peso_shield | 一致性 |
|--------|-----------|-------------|--------|
| 检测定位服务开启 | ✅ | ✅ | ✅ 100% |
| 权限状态细分 | ✅ 6 种 | ✅ 6 种 | ✅ 100% |
| 防重复请求 | ✅ | ✅ | ✅ 100% |
| 生命周期中断检测 | ✅ | ✅ | ✅ 100% |
| 4 种决策状态 | ✅ | ✅ | ✅ 100% |
| Native Bridge 集成 | ✅ | ✅ | ✅ 100% |
| permission_handler 降级 | ✅ | ✅ | ✅ 100% |
| 状态字符串返回 | 细粒度 | 合并 | 🟡 99% |

### 唯一差异的影响分析

**Native 返回值差异：**
- dali_cash: `"authorized_always"` / `"authorized_when_in_use"`
- peso_shield: `"authorized"`（合并）

**实际影响：** ✅ **无影响**

**原因：**
1. ✅ peso_shield 的 Dart 侧已经兼容了细粒度值
2. ✅ 业务逻辑都将两种授权视为 `granted`
3. ✅ peso_shield 只请求 `whenInUse`，不会出现 `always`
4. ✅ 两个项目的 `PermissionCoordinator` 逻辑完全一致

### 结论

✅ **peso_shield 的定位权限实现与 dali_cash 完全对齐**

- 核心逻辑 100% 一致
- 1 处细微差异不影响功能
- 所有高级特性完整实现：
  - ✅ 服务开启检测
  - ✅ 生命周期中断检测
  - ✅ 4 种决策状态
  - ✅ 防重复请求
  - ✅ 永久拒绝引导

**可选改进（非必需）：**
如果需要与 dali_cash 的返回值完全一致，可以将 peso_shield 的 `locationStatus()` 改为细粒度返回，但这对业务功能没有任何影响。

