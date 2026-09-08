# 准入流程定位权限检查 - 关键缺失功能已补全 ✅

## 问题描述

之前的实现**完全缺失**了 dali_cash 中最关键的功能：
- ❌ 产品准入时没有检查定位权限
- ❌ 没有在权限拒绝时中断准入流程
- ❌ 没有引导用户授权定位

## dali_cash 的实现

### 准入流程（DaliProductNavigationFlow.apply）
```dart
// 第 69 行：准入前必须检查定位权限
if (checkLocationAccess && !await ensureLocationAccess()) {
  return;  // 权限检查失败，中断准入流程
}

// 只有定位权限授权后，才继续调用 productApply API
await showLoading();
final response = await apiClient.productApply(...);
```

### 定位权限检查逻辑（_ensureLocationAccess）
```dart
static Future<bool> _ensureLocationAccess() async {
  // 1. 请求定位权限
  final decision = await certificationLocationRequester();
  
  // 2. 处理 4 种决策状态
  if (decision == CertificationLocationDecision.granted) {
    return true;  // 授权，继续准入
  }
  
  if (decision == CertificationLocationDecision.denied) {
    return false;  // 拒绝，中断准入
  }
  
  // 3. 服务未开启或需要去设置，显示引导对话框
  final serviceDisabled = 
      decision == CertificationLocationDecision.serviceDisabled;
  final openSettings = await permissionPromptPresenter(
    title: serviceDisabled
        ? 'Turn On Location Services'
        : 'Allow Location Access',
    content: serviceDisabled
        ? 'To help us confirm your identity and safeguard...'
        : "We couldn't verify your location because...",
    cancelText: 'Cancel',
    confirmText: 'Settings',
  );
  
  if (openSettings) {
    await appSettingsOpener();
  }
  
  return false;  // 未授权，中断准入
}
```

## peso_shield 的新实现 ✅

### 1. 在 ProductApplicationFlow 中添加定位权限检查

#### 修改的方法签名
```dart
Future<void> applyProduct({
  required BuildContext context,
  required String productId,
  int apiRemind = 0,
  bool checkLocationAccess = true,  // 新增参数，默认检查
}) async {
```

#### 准入流程中添加检查
```dart
// 1. 检查登录状态
if (!userSession.isLoggedIn) {
  await AppNavigator.toLogin();
  return;
}

if (!context.mounted) return;

// 2. 检查定位权限（新增！）
if (checkLocationAccess && !await _ensureLocationAccess(context)) {
  return; // 定位权限检查失败，中断准入流程
}

if (!context.mounted) return;

// 3. 调用准入接口
ToastHelper.showLoading();
final response = await repository.applyProduct(...);
```

#### 实现 _ensureLocationAccess 方法
```dart
/// 检查并请求定位权限（matching dali_cash）
Future<bool> _ensureLocationAccess(BuildContext context) async {
  final granted = await PermissionHelper.requestCertificationLocation(
    context,
    onGranted: () async {
      // 定位权限授权后，上报定位信息
      try {
        await reportService?.reportLocationAndDevice();
      } catch (error) {
        debugPrint('Location report after permission granted failed: $error');
      }
    },
  );

  return granted;
}
```

### 2. PermissionHelper 已有完整支持

之前已经实现的 `PermissionHelper.requestCertificationLocation()` 包含：
- ✅ 调用 `PermissionCoordinator.requestCertificationLocation()`
- ✅ 处理 4 种决策状态（granted/denied/settingsRequired/serviceDisabled）
- ✅ 显示引导对话框（服务未开启/权限被拒绝）
- ✅ 跳转到系统设置

## 完整的准入流程对比

### dali_cash
```
用户点击申请
  ↓
检查登录
  ↓
检查定位权限 ← 关键
  ├─ 授权 → 继续
  ├─ 拒绝 → 中断
  ├─ 服务未开启 → 显示对话框 → 中断
  └─ 需要设置 → 显示对话框 → 中断
  ↓
调用 productApply API
  ↓
处理响应
```

### peso_shield（之前）
```
用户点击申请
  ↓
检查登录
  ↓
直接调用 productApply API ← 缺失定位权限检查！
  ↓
处理响应
```

### peso_shield（现在）✅
```
用户点击申请
  ↓
检查登录
  ↓
检查定位权限 ← 已补全！
  ├─ 授权 → 继续
  ├─ 拒绝 → 中断
  ├─ 服务未开启 → 显示对话框 → 中断
  └─ 需要设置 → 显示对话框 → 中断
  ↓
调用 productApply API
  ↓
处理响应
```

## 修改的文件

### `lib/core/product/product_application_flow.dart`
- ✅ 导入 `permission_helper.dart`
- ✅ 添加 `checkLocationAccess` 参数
- ✅ 在准入前调用 `_ensureLocationAccess()`
- ✅ 实现 `_ensureLocationAccess()` 方法

## 对比总结

| 功能点 | dali_cash | peso_shield (之前) | peso_shield (现在) |
|--------|-----------|-------------------|-------------------|
| 准入前检查定位权限 | ✅ | ❌ | ✅ |
| 权限拒绝中断准入 | ✅ | ❌ | ✅ |
| 服务未开启引导 | ✅ | ❌ | ✅ |
| 权限被拒引导设置 | ✅ | ❌ | ✅ |
| 授权后上报定位 | ✅ | ❌ | ✅ |
| 4 种决策状态处理 | ✅ | ❌ | ✅ |

## 业务影响

### 之前的问题
⚠️ **准入流程没有定位权限检查**
- 用户可以在未授权定位的情况下进入准入流程
- 后端无法获取准确的定位信息
- 风控能力不足

### 现在的改进
✅ **完整的定位权限保护**
- 准入前强制检查定位权限
- 权限未授权时中断流程
- 友好的引导对话框
- 与 dali_cash 行为完全一致

## 验证

```bash
# 构建成功
flutter build ios --no-codesign --debug
✓ Built build/ios/iphoneos/Runner.app

# 代码分析通过
flutter analyze lib/core/product/product_application_flow.dart
No issues found!
```

## 总结

✅ **已完全对齐 dali_cash 的准入流程定位权限检查**

**之前缺失的功能：**
1. ❌ 准入前定位权限检查
2. ❌ 权限拒绝时的流程中断
3. ❌ 用户引导对话框

**现在已补全：**
1. ✅ 准入前强制检查定位权限
2. ✅ 权限未授权时中断准入流程
3. ✅ 显示友好的引导对话框
4. ✅ 授权后自动上报定位信息
5. ✅ 与 dali_cash 行为完全一致

**这是权限管理中最关键的业务逻辑，现在已经完整实现！** 🎉
