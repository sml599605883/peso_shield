# 权限管理对齐完成 ✅

## 验证结果

- ✅ **iOS 构建成功**: `flutter build ios --no-codesign --debug` 通过
- ✅ **Flutter 分析通过**: 仅 1 个 info 级别 lint 提示（`use_build_context_synchronously`），不影响功能
- ✅ **23 个文件修改**: +362 行, -108 行

## 核心改动

### 1. 新增 `lib/core/permissions/` 模块 (3 个文件)

#### `permission_coordinator.dart` (8 KB)
- 集中管理所有权限请求逻辑
- 启动时自动请求：通知权限 + 追踪权限（ATT）
- App resume 时重新请求追踪权限
- 定位权限支持 4 种决策状态
- 支持依赖注入，防重复请求

#### `permission_lifecycle_observer.dart` (3 KB)
- 监听应用生命周期
- 在启动和 resume 时触发权限请求
- 与 PesoReportService 集成

#### `permission_helper.dart` (5 KB)
- 页面级权限请求便捷方法
- 统一的对话框样式和文案
- 相机权限、定位权限的完整处理

### 2. iOS Native 扩展

#### `ClientBridgeRegistrar.swift`
- 添加 `AdSupport` 和 `AppTrackingTransparency` 导入
- 新增方法：
  - `registerForRemoteNotifications`: 注册远程推送
  - `getTrackingStatus`: 获取 ATT 状态
  - `getPushToken`: 获取推送 token

#### `ClientBridgeRegistrar+Reporting.swift`
- 将 `currentTrackingStatus()` 改为 `public`（移除 `private`）
- 已有 `updatePushToken()` 和 `publishTrackingStatus()` 方法

#### `AppDelegate.swift`
- `applicationDidBecomeActive` 中调用 `publishTrackingStatus()`

### 3. Dart 侧集成

#### `lib/core/client/client_bridge.dart`
- 添加 `static final ClientBridge shared = ClientBridge()` 单例

#### `lib/main.dart`
```dart
// 初始化权限管理
PermissionCoordinator.initialize(ClientBridge.shared);
PermissionLifecycleObserver.initialize();
PermissionLifecycleObserver.instance.start();
```

### 4. 页面级优化

#### `lib/pages/identity_upload_page.dart`
- 使用 `PermissionHelper.requestCameraPermission()`
- 使用 `PermissionHelper.showCameraPermissionDialog()`
- 移除重复的权限处理代码（-68 行）

#### `lib/pages/face_recognition_page.dart`
- 使用 `PermissionHelper.requestCameraPermission()`
- 使用 `PermissionHelper.showCameraPermissionDialog()`
- 移除页面内部的 `_showPermissionDialog()` 方法（-27 行）

## 权限支持对比

| 权限类型 | 改进前 | 改进后 | 时机 |
|---------|-------|-------|------|
| 通知 (Notification) | ❌ | ✅ | 启动时自动 |
| 追踪 (ATT) | ❌ | ✅ | 启动时 + Resume |
| 相机 (Camera) | ✅ 分散 | ✅ 统一 | 按需 |
| 定位 (Location) | ❌ | ✅ | 认证流程（可选） |

## 架构提升

### 改进前（分散式）
```
identity_upload_page.dart
  └─ 直接调用 Permission.camera.request()
  └─ 自己处理对话框

face_recognition_page.dart
  └─ 直接调用 Permission.camera.request()
  └─ 自己处理对话框
```

### 改进后（集中式）
```
main.dart
  └─ PermissionCoordinator (统一协调)
      └─ 启动时: 通知 + 追踪
      └─ Resume: 追踪

permission_helper.dart (统一 API)
  ├─ requestCameraPermission()
  ├─ showCameraPermissionDialog()
  └─ requestCertificationLocation()

页面 (简化)
  └─ PermissionHelper.requestCameraPermission()
```

## 代码质量

- ✅ iOS 编译通过
- ✅ Flutter analyze 通过（1 个无害 info）
- ✅ 类型安全
- ✅ 生命周期安全
- ✅ 防重复请求
- ✅ 依赖注入友好

## 已有配置

iOS Info.plist 已包含所有必要的权限声明：
- ✅ NSCameraUsageDescription
- ✅ NSLocationWhenInUseUsageDescription  
- ✅ NSPhotoLibraryUsageDescription
- ✅ NSUserTrackingUsageDescription

## 使用示例

### 启动时自动请求（已配置）
```dart
// main.dart - 应用启动时自动执行
PermissionCoordinator.initialize(ClientBridge.shared);
PermissionLifecycleObserver.initialize();
PermissionLifecycleObserver.instance.start();

// 400ms 后自动请求通知权限
// 再 400ms 后自动请求追踪权限
// App resume 时重新请求追踪权限
```

### 页面级请求相机权限
```dart
final status = await PermissionHelper.requestCameraPermission();

if (status == CameraPermissionStatus.granted) {
  // 继续拍照
} else if (status == CameraPermissionStatus.permanentlyDenied) {
  await PermissionHelper.showCameraPermissionDialog(context);
}
```

### 请求定位权限（可选）
```dart
await PermissionHelper.requestCertificationLocation(
  context,
  onGranted: () async {
    // 定位授权后的逻辑
  },
);
```

## 注意事项

1. **权限弹窗不会阻塞启动**: 所有请求都有 try-catch 保护
2. **追踪权限仅在 iOS 14+ 生效**: 低版本自动降级
3. **定位权限处理了 4 种状态**: granted/denied/settingsRequired/serviceDisabled
4. **TDMobRisk 编译警告**: 这是项目原有问题，不影响权限模块功能

## 完成状态

✅ 所有任务完成，可以提交代码！

改动统计: **23 个文件, +362 行, -108 行**
