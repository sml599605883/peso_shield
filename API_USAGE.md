# Peso Shield API 使用指南

## 概述

Peso Shield项目已实现完整的网络层，包括AES加密、签名、混淆参数等安全机制。

## 架构特点

### 1. 安全机制
- ✅ **AES加密**：所有请求参数自动加密
  - Key: `ea0deb3b9018009f`
  - IV: `031dcd3b521e5cf6`
- ✅ **请求签名**：使用MD5签名验证请求完整性
  - Secret: `cf938da7bebcecccd5563ca28d7f1fbd`
- ✅ **混淆参数**：自动生成随机数字混淆参数

### 2. 统一调用入口
使用`ApiService`统一访问所有接口，避免导入多个repository文件。

## 快速开始

### 1. 获取ApiService实例

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/providers/network_provider.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiServiceProvider);
    
    // 现在可以使用api调用所有接口
    return Container();
  }
}
```

### 2. 调用接口示例

#### 用户认证
```dart
// 发送验证码
final result = await api.auth.sendVerificationCode(
  phone: '09123456789',
  channel: 'sms', // sms, voice, viber
);

// 登录
final loginResult = await api.auth.login(
  phone: '09123456789',
  code: '123456',
);

// 退出登录
await api.auth.logout();

// 注销账号
await api.auth.deleteAccount();
```

#### 获取首页数据
```dart
final homeData = await api.app.getHomePage();
```

#### 产品相关
```dart
// 申请产品
final applyResult = await api.product.applyProduct(
  productId: '1000459',
  apiRemind: 0,
);

// 获取产品详情
final productDetail = await api.product.getProductDetail(
  productId: '1000459',
);
```

#### 认证项
```dart
// 获取用户身份信息
final identityData = await api.certification.getIdentityInfo(
  productId: '1000459',
);

// 上传图片
final imageUrl = await api.certification.uploadImage(
  imageData: base64ImageData,
  imageType: 'face', // face, id_card_front
);

// 保存身份证信息
await api.certification.saveIdentityInfo(
  birthDate: '1990/01/01',
  idNumber: 'ABC123456',
  fullName: 'Juan Dela Cruz',
  type: '1',
  cardType: '1',
);

// 获取face++token
final token = await api.certification.getFacePPToken(
  orderNo: '302021063003045300522743',
  type: 0,
);

// 获取个人信息
final personalInfo = await api.certification.getPersonalInfo(
  productId: '1000459',
);

// 保存个人信息
await api.certification.savePersonalInfo(
  productId: '1000459',
  formData: {
    'pulis': '1',
    'brakiest': '1',
    // ... 其他字段
  },
);

// 获取工作信息
final workInfo = await api.certification.getWorkInfo(
  productId: '1000459',
);

// 保存工作信息
await api.certification.saveWorkInfo(
  productId: '1000459',
  formData: {
    'gelatins': 'Company Name',
    'mehndis': 'Industry',
    // ... 其他字段
  },
);

// 获取联系人信息
final contactInfo = await api.certification.getContactInfo(
  productId: '1000459',
);

// 保存联系人
await api.certification.saveContactInfo(
  productId: '1000459',
  contacts: [
    {
      'injure': '09123456789',
      'cymenes': 'Contact Name',
      'briner': '1',
      'searchers': 'first',
    },
    // ... 更多联系人
  ],
);

// 获取绑卡信息
final bankInfo = await api.certification.getBankInfo(
  productId: '1000459',
);

// 提交绑卡
await api.certification.submitBankCard(
  productId: '1000459',
  accountType: '1', // 1:电子钱包, 2:银行, 3:便利店
  accountNumber: '09123456789',
  firstName: 'Juan',
  middleName: 'D',
  lastName: 'Cruz',
);

// 获取用户账户列表
final accounts = await api.certification.getUserBankAccounts(
  productId: '1000459',
);

// 获取地址初始化数据
final addressData = await api.certification.getAddressInit();
```

#### 订单相关
```dart
// 获取订单跳转URL
final jumpUrl = await api.order.getOrderJumpUrl(
  orderNo: '302021063003045300522743',
  amount: '1000000',
  loanTerm: '7',
  termType: 'day',
);

// 获取订单列表
final orderList = await api.order.getOrderList(
  page: 1,
  pageSize: 20,
);
```

#### 数据上报
```dart
// 上报位置信息
await api.report.reportLocation(
  countryCode: 'PH',
  country: 'Philippines',
  street: 'Main Street',
  latitude: 14.5995,
  longitude: 120.9842,
  city: 'Manila',
  province: 'Metro Manila',
);

// Google Market上报
await api.report.reportGoogleMarket(
  idfv: '989fdcf7-1c27-412e-85f4-04f7f8e1f406',
  idfa: '989fdcf7-1c27-412e-85f4-04f7f8e1f406',
);

// 上报风控埋点
await api.report.reportRiskEvent(
  productId: '1000459',
  sceneType: '1',
  orderNo: '302021063003045300522743',
  newDeviceId: 'device_id',
  advertisingId: 'ad_id',
  longitude: 120.9842,
  latitude: 14.5995,
  startTime: '1653818095000',
  endTime: '1653818330000',
);

// 上报设备信息（需要加密）
await api.report.reportDeviceInfo(
  encryptedData: encryptedDeviceData,
);

// 上报Apple推送token
await api.report.reportApplePushToken(
  token: 'push_token_here',
);
```

#### App上报
```dart
await api.app.reportAppEvent(
  eventType: '1', // 1:动态域名上报, 2:流程埋点上报
  eventData: 'event_data_json_string',
);
```

## 错误处理

所有接口返回`ApiResponse<T>`类型，包含响应码、消息和数据：

```dart
try {
  final response = await api.auth.login(
    phone: phone,
    code: code,
  );
  
  if (response.code == 0) {
    // 成功
    final loginData = response.data;
    print('Token: ${loginData.token}');
  } else {
    // 业务错误
    print('Error: ${response.message}');
  }
} on HttpException catch (e) {
  // 网络或其他错误
  print('Exception: ${e.message}');
}
```

## 接口统计

| 模块 | 接口数量 |
|------|---------|
| 用户认证 | 4 |
| App相关 | 2 |
| 产品相关 | 2 |
| 认证项 | 13 |
| 订单相关 | 2 |
| 数据上报 | 5 |
| **总计** | **28** |

## 注意事项

1. **混淆参数**：所有空字符串混淆参数已自动使用`ObfuscationHelper.randomParam()`生成随机6位数字
2. **加密传输**：所有请求会自动进行AES加密和签名，无需手动处理
3. **统一调用**：使用`apiServiceProvider`获取`ApiService`实例，通过`.auth`、`.product`等访问各模块接口
4. **Provider管理**：所有网络实例通过Riverpod管理，支持依赖注入和状态管理
