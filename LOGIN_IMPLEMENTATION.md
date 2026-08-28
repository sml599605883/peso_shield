# 登录功能实现说明

## 概述
基于 fund_nexus 项目的登录逻辑，为 peso_shield 项目实现了完整的登录功能。

## 新增文件
- `lib/pages/login/login_state.dart` - 登录状态管理

## 修改文件
- `lib/pages/login_page.dart` - 登录页面UI和逻辑

## 实现的功能

### 1. 状态管理（login_state.dart）
使用 Riverpod 的 `Notifier` 模式管理登录状态：
- **agreementAccepted**: 用户是否同意协议
- **requestingCode**: 是否正在请求验证码
- **loggingIn**: 是否正在登录
- **countdownSeconds**: 验证码倒计时秒数

### 2. 验证码发送倒计时
- 点击"Get Code"后开始60秒倒计时
- 倒计时期间按钮显示剩余秒数（如"59s"）
- 倒计时期间按钮禁用，防止重复请求
- 倒计时结束后恢复"Get Code"状态

### 3. 输入限制和自动提交
- 验证码输入框限制为数字，最多6位
- 使用 `FilteringTextInputFormatter.digitsOnly` 限制只能输入数字
- 使用 `LengthLimitingTextInputFormatter(6)` 限制最多6位
- 当输入满6位验证码时，自动触发登录提交
- 如果自动提交失败且已同意协议，清空验证码并重新聚焦输入框

### 4. 表单验证
- 手机号不能为空
- 验证码必须是6位数字
- 必须同意隐私政策和服务条款才能登录

### 5. 协议和隐私政策处理
- 使用 `TapGestureRecognizer` 实现文本内链接点击
- 点击复选框切换协议同意状态
- 点击"Privacy Policy"链接独立处理（不影响复选框状态）
- 支持通过 `onPrivacyPolicyTap` 回调自定义隐私政策页面打开行为
- 默认行为为 debugPrint（开发阶段）

### 6. 用户体验优化
- 验证码发送成功后自动聚焦验证码输入框
- 点击页面空白处自动收起键盘（使用 GestureDetector）
- 添加 FocusNode 管理输入框焦点
- 登录按钮状态根据表单完整性和协议同意状态动态变化
- 加载状态时显示 CircularProgressIndicator

### 7. 错误处理
- 网络请求失败时显示友好的错误提示
- API 返回错误时显示服务器返回的错误信息
- 使用 SnackBar 显示所有提示信息

### 8. 按钮状态管理
- **Get Code 按钮**:
  - 正常状态：显示"Get Code"，橙色文字
  - 请求中：显示 loading 动画
  - 倒计时中：显示剩余秒数，灰色文字，禁用点击

- **登录按钮**:
  - 表单未填写完整或未同意协议：灰色背景，禁用
  - 表单完整且已同意协议：渐变色背景，可点击
  - 登录中：显示 loading 动画

## 技术实现细节

### 状态管理
使用 Riverpod 3.3.2 的 `Notifier` API：
```dart
class LoginStateNotifier extends Notifier<LoginState> {
  @override
  LoginState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const LoginState();
  }
}
```

### 倒计时实现
使用 `Timer.periodic` 实现秒级倒计时：
```dart
void startCountdown({int seconds = 60}) {
  _countdownTimer?.cancel();
  state = state.copyWith(countdownSeconds: seconds);
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (state.countdownSeconds <= 1) {
      timer.cancel();
      state = state.copyWith(countdownSeconds: 0);
    } else {
      state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
    }
  });
}
```

### 自动提交逻辑
监听验证码输入变化，输入满6位时自动提交：
```dart
void _onCodeChanged() {
  setState(() {});
  if (_codeController.text.length == 6) {
    unawaited(_submitAutomatically());
  }
}
```

### 协议文本链接处理
使用 `TapGestureRecognizer` 实现 RichText 内的独立点击：
```dart
class _AgreementState extends State<_Agreement> {
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = widget.onPrivacyPolicyTap;
  }

  @override
  void dispose() {
    _privacyPolicyRecognizer.dispose();
    super.dispose();
  }
}
```

## API 使用示例

### 基本使用
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LoginPage(),
  ),
);
```

### 自定义隐私政策点击
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LoginPage(
      onPrivacyPolicyTap: () {
        // 打开隐私政策页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivacyPolicyPage(),
          ),
        );
      },
    ),
  ),
);
```

### 自定义登录成功回调
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LoginPage(
      onLoginSuccess: () async {
        // 登录成功后的自定义逻辑
        await loadUserProfile();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
    ),
  ),
);
```

## 与 fund_nexus 的差异
1. **状态管理**: fund_nexus 使用 Bloc/Cubit，peso_shield 使用 Riverpod
2. **API 调用**: 保持各自项目的 API 结构和命名
3. **UI 样式**: 保持 peso_shield 原有的设计风格
4. **代码结构**: 适应 peso_shield 的项目结构
5. **协议文案**: peso_shield 只显示 Privacy Policy，fund_nexus 包含 Terms of Service

## 测试建议
1. 测试手机号输入和验证码发送
2. 测试60秒倒计时功能
3. 测试验证码输入限制（只能输入数字，最多6位）
4. 测试自动提交功能（输入6位验证码后）
5. 测试协议勾选状态对登录按钮的影响
6. **测试 Privacy Policy 链接点击（不应切换复选框）**
7. **测试复选框区域点击（应切换选中状态）**
8. 测试各种错误场景（网络错误、验证码错误等）
9. 测试键盘交互和焦点管理

## 依赖项
无需添加新的依赖，使用现有的：
- flutter_riverpod: ^3.3.2
- flutter/services.dart (用于输入格式化)
- flutter/gestures.dart (用于文本链接点击)
