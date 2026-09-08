# 权限管理对齐 dali_cash

## 概述
已成功将 peso_shield 的权限管理架构对齐到 dali_cash 的水平，实现了集中式、生命周期驱动的权限管理系统。

## 完成的改动

### 1. 创建 `core/permissions/` 模块 ✅

#### `permission_coordinator.dart`
- **PermissionCoordinator**: 集中管理所有权限请求逻辑
  - 启动时自动请求：通知权限 + 追踪权限（ATT）
  - App resume 时重新请求追踪权限
  - 定位权限的高级协调逻辑（处理 4 种决策状态）
  - 支持依赖注入，方便测试

- **CertificationLocationDecision**: 定位权限决策枚举
  - `granted`: 已授权
  - `denied`: 拒绝
  - `settingsRequired`: 需要去设置
  - `serviceDisabled`: 定位服务未开启

#### `permission_lifecycle_observer.dart`
- **PermissionLifecycleObserver**: 监听应用生命周期
  - 启动时自动请求权限
  - Resume 时重新请求追踪权限
  - 与 PesoReportService 集成，上报权限相关事件

#### `permission_helper.dart`
- 提供页面级权限请求的便捷方法
- 统一的对话框样式和文案
- 相机权限、定位权限的完整处理流程

### 2. 扩展 ClientBridge ✅

#### Dart 侧 (`lib/core/client/client_bridge.dart`)
- 添加 `shared` 单例，方便全局访问
- 已有 `registerForRemoteNotifications()` 方法
- 已有 `getTrackingStatus()` 方法
- 已有 `getPushToken()` 方法

#### Swift 侧 (`ios/Runner/ClientBridgeRegistrar.swift`)
- 添加 `FlutterStreamHandler` 协议支持
- 添加 `eventChannel` 支持事件流
- 实现 `registerForRemoteNotifications` 方法调用
- 实现 `getTrackingStatus` 方法，返回 ATT 状态
- 实现 `getPushToken` 方法
- 添加 `publishTrackingStatus()` 方法，在 app 激活时发布追踪状态
- 添加 `updatePushToken()` 方法，推送 token 更新时通知 Flutter

#### AppDelegate (`ios/Runner/AppDelegate.swift`)
- `applicationDidBecomeActive` 中调用 `publishTrackingStatus()`
- 已有推送 token 注册和失败回调

### 3. 在 main.dart 中初始化 ✅

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize permission management
  PermissionCoordinator.initialize(ClientBridge.shared);
  PermissionLifecycleObserver.initialize();
  PermissionLifecycleObserver.instance.start();
  
  runApp(const ProviderScope(child: PesoShieldApp()));
}
```

### 4. 更新现有页面 ✅

#### `identity_upload_page.dart`
- 移除页面内部的权限请求逻辑
- 使用 `PermissionHelper.requestCameraPermission()`
- 使用 `PermissionHelper.showCameraPermissionDialog()`
- 移除重复的 `CameraPermissionStatus` enum 定义

#### `face_recognition_page.dart`
- 移除 `permission_handler` 直接导入
- 使用 `PermissionHelper.requestCameraPermission()`
- 使用 `PermissionHelper.showCameraPermissionDialog()`
- 移除页面内部的 `_showPermissionDialog()` 方法

### 5. iOS Info.plist 权限声明 ✅

已有完整的权限声明：
- ✅ `NSCameraUsageDescription`: 相机权限
- ✅ `NSLocationWhenInUseUsageDescription`: 定位权限
- ✅ `NSPhotoLibraryUsageDescription`: 相册权限
- ✅ `NSUserTrackingUsageDescription`: 追踪权限（ATT）

## 与 dali_cash 的对比

| 功能 | dali_cash | peso_shield (改进后) | 状态 |
|------|-----------|---------------------|------|
| 集中式权限管理 | ✅ | ✅ | 完全对齐 |
| 启动时请求通知权限 | ✅ | ✅ | 完全对齐 |
| 启动时请求追踪权限 | ✅ | ✅ | 完全对齐 |
| Resume 时重新请求追踪 | ✅ | ✅ | 完全对齐 |
| 定位权限协调逻辑 | ✅ | ✅ | 完全对齐 |
| 生命周期观察者 | ✅ | ✅ | 完全对齐 |
| Native Bridge 支持 | ✅ | ✅ | 完全对齐 |
| Event Channel | ✅ | ✅ | 完全对齐 |
| 页面级统一 API | ✅ | ✅ | 完全对齐 |

## 权限请求时机

### 应用启动时（自动）
1. 延迟 400ms
2. 请求通知权限
3. 注册远程推送
4. 延迟 400ms
5. 请求追踪权限（iOS 14+ ATT）

### 应用恢复时（自动）
- 重新请求追踪权限

### 用户触发时（按需）
- 相机权限：拍照上传、人脸识别
- 定位权限：认证流程中按需请求

## 代码质量

- ✅ Flutter analyze 通过（1 个 info 级别的 lint 建议，不影响功能）
- ✅ 类型安全
- ✅ 支持依赖注入
- ✅ 生命周期安全（处理 app pause/detach）
- ✅ 避免重复请求（防抖逻辑）

## 注意事项

1. **权限弹窗不会阻塞启动**：所有权限请求都包裹在 try-catch 中
2. **追踪权限仅在 iOS 14+ 生效**：低版本自动降级
3. **定位权限处理了 4 种状态**：granted、denied、settingsRequired、serviceDisabled
4. **页面级权限请求是独立的**：不会干扰启动时的权限请求

## 后续可选增强

1. 如果需要在认证流程中请求定位权限，可以使用：
   ```dart
   await PermissionHelper.requestCertificationLocation(
     context,
     onGranted: () async {
       // 定位授权后的逻辑
     },
   );
   ```

2. 如果需要监听推送 token 变化，可以监听 `ClientBridge.shared.reportEvents()`

3. 如果需要在特定场景请求其他权限，可以扩展 `PermissionHelper`
