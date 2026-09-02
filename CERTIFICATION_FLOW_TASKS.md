# 认证流程补充任务清单

基于 dali_cash 的完整实现，peso_shield 需要补充以下认证流程相关功能。

---

## 📋 任务优先级说明

- 🔴 **P0**：核心流程，必须完成
- 🟡 **P1**：重要功能，建议尽快完成
- 🟢 **P2**：优化项，可后续迭代

---

## 🔴 P0 任务：核心认证流程

### 1. 完善证件上传页的实际上传功能 ✅
**文件位置**：`lib/pages/identity_upload_page.dart`

**当前状态**：
- ✅ 静态引导页已完成
- ✅ 上传方式弹窗已完成
- ✅ 相机/相册调用已实现
- ✅ 图片上传和 OCR 已实现
- ⚠️ 上传成功后的导航待任务2完成（确认页）

**需要实现的功能**：
1. **相机拍照功能**
   - 集成 `image_picker` 或类似插件
   - 调用原生相机拍摄证件照
   - 图片质量压缩和尺寸优化（建议 <= 500KB）

2. **相册选择功能**
   - 从手机相册选择已有照片
   - 支持图片裁剪和旋转

3. **图片上传和 OCR**
   - 调用 `CertificationRepository.uploadImage` 上传 base64 图片
   - 参数：`imageData`（base64）、`imageType`（证件类型）
   - 接口：`POST /outsmelled/slouchinesses`
   - 处理返回的 OCR 识别结果

4. **导航到确认页**
   - 上传成功后跳转到证件确认页
   - 传递参数：`productId`、`cardType`、`recognizedInfo`（OCR 结果）
   - 使用 `Get.toNamed` 或 `AppNavigator.toNamed`

**参考文件**：
- `dali_cash/lib/features/certification/identity_upload/identity_upload_page.dart`
- `dali_cash/lib/features/certification/identity_upload/identity_upload_data.dart`

**估计工作量**：2-3 天

---

### 2. 创建证件确认页（OCR 结果审核）
**文件位置**：新建 `lib/pages/identity_confirmation_page.dart`

**页面功能**：
1. **UI 展示**
   - 顶部导航栏：标题 "Identity verification"
   - 中间区域：表单字段
   - 底部按钮："Submit"

2. **表单字段**（预填充 OCR 结果）
   - 姓名（Full Name）- 文本输入框
   - 证件号码（ID Number）- 文本输入框
   - 生日（Birthday）- 日期选择器

3. **数据校验**
   - 所有字段必填
   - 证件号码格式校验（根据证件类型）
   - 生日格式：YYYY-MM-DD

4. **提交逻辑**
   - 调用 `CertificationRepository.saveIdentityInfo`
   - 参数：`birthDate`、`idNumber`、`fullName`、`type`、`cardType`
   - 接口：`POST /outsmelled/bewails`
   - 成功后调用 `ReportRepository.reportRisk(scene: 3)` 上报风险
   - 然后调用 `ProductApplicationFlow.continueProductDetailFlow(productId)` 进入下一步

5. **路由配置**
   - 在 `AppRoutes` 中添加：`static const String identityConfirmation = '/identity-confirmation';`
   - 在 `AppRouteGenerator` 中添加路由映射
   - 在 `AppNavigator` 中添加导航方法：`toIdentityConfirmation`

**参考文件**：
- `dali_cash/lib/features/certification/identity_confirmation/identity_confirmation_page.dart`
- `dali_cash/lib/features/certification/identity_confirmation/identity_birthday_picker.dart`

**估计工作量**：2 天

---

### 3. 创建 continueProductDetailFlow 方法
**文件位置**：`lib/core/product/product_application_flow.dart`

**功能描述**：
- 这是认证流程的核心调度方法
- 每个认证步骤完成后都调用此方法获取下一步指令

**实现逻辑**：
1. **调用产品详情接口**
   - `ProductRepository.getProductDetail(productId)`
   - 接口：`POST /outsmelled/beamier`（根据实际项目确认）

2. **解析 nextStep.taskType**
   - 从 `ProductDetail.nextStep.taskType` 获取下一步类型
   - 类型对应关系（混淆后的值）：
     - `Outpulls` → 身份认证（证件类型选择）
     - `ViscosimeterDollop` → 活体认证
     - `Unconcernedness` → 个人信息
     - `Jammable` → 工作信息
     - `Pip` → 紧急联系人
     - `Reentrance` → 银行卡绑定

3. **路由调度**
   - 根据 `taskType` 跳转到对应页面
   - 如果 `taskType` 为空，表示所有认证完成
   - 此时调用借款目标接口或跳转到确认页

**代码框架**：
```dart
Future<void> continueProductDetailFlow({
  required BuildContext context,
  required String productId,
}) async {
  final detail = await fetchProductDetail(context: context, productId: productId);
  if (detail == null || !context.mounted) return;
  
  await _continueFromDetail(context, detail, productId);
}
```

**估计工作量**：1 天

---

### 4. 创建活体认证页
**文件位置**：新建 `lib/pages/identity_face_page.dart`

**页面功能**：
1. **UI 展示**
   - 顶部导航栏
   - 活体认证引导文案（从产品详情缓存获取）
   - 活体认证动画/说明图
   - 底部按钮："Start verification"

2. **活体认证流程**
   - 调用 `CertificationRepository.getFacePPToken` 获取活体 token
   - 参数：`orderNo`（从 SessionStore 获取）、`type: 0`
   - 接口：`POST /outsmelled/kestrel`
   - 集成 TrustDecision 或 FacePP SDK（根据项目实际情况）
   - SDK 返回活体结果后上报：`POST /lutes/adapting`（需要添加到 repository）
   - 上传活体照片：`CertificationRepository.uploadImage`

3. **风险上报**
   - 成功后调用 `ReportRepository.reportRisk(scene: 4)`

4. **下一步**
   - 调用 `continueProductDetailFlow(productId)`

**路由配置**：
- `AppRoutes.identityFace = '/identity-face'`
- `AppNavigator.toIdentityFace(productId: String)`

**注意事项**：
- SDK 集成可能需要原生代码修改（iOS/Android）
- 需要处理 SDK 初始化失败、网络失败等异常情况
- 活体照片需要转换为 base64 格式上传

**参考文件**：
- `dali_cash/lib/features/certification/identity_face/identity_face_page.dart`

**估计工作量**：3-4 天（含 SDK 集成）

---

### 5. 创建共享动态表单引擎
**文件位置**：新建 `lib/widgets/dynamic_form/`

**功能描述**：
- 根据 API 返回的字段配置动态渲染表单
- 个人信息页和工作信息页都复用此引擎

**组件结构**：
```
lib/widgets/dynamic_form/
├── dynamic_form_page.dart          # 主页面框架
├── dynamic_form_field.dart         # 单个字段渲染
├── dynamic_form_controller.dart    # 表单控制器
└── field_types/
    ├── text_field.dart             # 文本输入
    ├── selection_field.dart        # 单选/下拉
    ├── address_field.dart          # 地址级联选择
    └── date_field.dart             # 日期选择
```

**API 字段配置格式**（参考 dali_cash）：
```json
{
  "enterostomy": "Email Address",           // 字段标题
  "laggings": "Enter your email",           // 占位符
  "felicitous": "email",                    // 提交时的参数名
  "fyke": "user@example.com",               // 当前值
  "solferino": "haphtaras",                 // 控件类型（混淆值）
  "muscats": 0,                             // 是否必填（0=必填，1=可选）
  "omegas": 1,                              // 是否数字键盘（1=是）
  "poolsides": [...]                        // 选择型字段的选项列表
}
```

**控件类型映射**（参考 dali_cash）：
- `haphtaras` → 文本输入
- `krimmersopinioned` → 单选/下拉选择
- `superpower` → 地址级联选择
- 其他 → 不支持的类型

**表单提交**：
- 遍历所有字段，构建 `{ field.saveKey: value }` 的 Map
- 调用对应的保存接口

**参考文件**：
- `dali_cash/lib/features/certification/certification_information/certification_information_page.dart`
- `dali_cash/lib/features/certification/personal_information/personal_information_data.dart`

**估计工作量**：3-4 天

---

### 6. 创建个人信息页
**文件位置**：新建 `lib/pages/personal_information_page.dart`

**页面功能**：
1. **基于动态表单引擎**
   - 复用上面创建的 `DynamicFormPage`
   - 传递配置参数

2. **页面配置**
   - 标题："Basic identity information"
   - 进度展示：可选的进度条或步骤指示器

3. **数据获取**
   - 调用 `CertificationRepository.getPersonalInfo(productId)`
   - 接口：`POST /outsmelled/satinwood`
   - 如需地址数据，调用 `CertificationRepository.getAddressInit()`
   - 接口：`GET /outsmelled/succedanea`

4. **提交逻辑**
   - 调用 `CertificationRepository.savePersonalInfo(productId, formData)`
   - 接口：`POST /outsmelled/wazoo`
   - 风险上报：`ReportRepository.reportRisk(scene: 5)`
   - 下一步：`continueProductDetailFlow(productId)`

**路由配置**：
- `AppRoutes.personalInformation = '/personal-information'`
- `AppNavigator.toPersonalInformation(productId: String)`

**参考文件**：
- `dali_cash/lib/features/certification/personal_information/personal_information_page.dart`

**估计工作量**：1 天（依赖动态表单引擎完成）

---

### 7. 创建工作信息页
**文件位置**：新建 `lib/pages/work_information_page.dart`

**页面功能**：
1. **基于动态表单引擎**
   - 与个人信息页类似，复用 `DynamicFormPage`

2. **页面配置**
   - 标题："Job information"

3. **数据获取**
   - 调用 `CertificationRepository.getWorkInfo(productId)`
   - 接口：`POST /outsmelled/indissoluble`

4. **提交逻辑**
   - 调用 `CertificationRepository.saveWorkInfo(productId, formData)`
   - 接口：`POST /outsmelled/applicants`
   - 风险上报：`ReportRepository.reportRisk(scene: 6)`
   - 下一步：`continueProductDetailFlow(productId)`

**路由配置**：
- `AppRoutes.workInformation = '/work-information'`
- `AppNavigator.toWorkInformation(productId: String)`

**参考文件**：
- `dali_cash/lib/features/certification/work_information/work_information_page.dart`

**估计工作量**：1 天（依赖动态表单引擎完成）

---

### 8. 创建紧急联系人页
**文件位置**：新建 `lib/pages/emergency_contact_page.dart`

**页面功能**：
1. **UI 展示**
   - 顶部导航栏
   - 多个联系人卡片（根据 API 返回的槽位数量动态生成）
   - 每个卡片包含：
     - 关系选择（底部弹窗）
     - 姓名输入
     - 电话输入
     - "从通讯录选择" 按钮
   - 底部提交按钮

2. **数据获取**
   - 调用 `CertificationRepository.getContactInfo(productId)`
   - 接口：`POST /outsmelled/outduelled`
   - 返回格式：N 个联系人槽位，每个槽位有关系选项列表

3. **原生通讯录选择**
   - 集成 `contacts_service` 或类似插件
   - 用户点击后打开系统通讯录
   - 选择联系人后自动填充姓名和电话

4. **数据校验**
   - 所有联系人槽位必须填写完整
   - 电话号码格式校验
   - 不同联系人的电话号码不能重复

5. **提交逻辑**
   - 调用 `CertificationRepository.saveContactInfo(productId, contacts)`
   - 接口：`POST /outsmelled/geochronologist`
   - 参数：`contacts` 是一个 List，每项包含 `{ relationship, name, phone }`
   - （可选）批量上传通讯录：`POST /lutes/climatological`
   - 下一步：`continueProductDetailFlow(productId)`

**路由配置**：
- `AppRoutes.emergencyContact = '/emergency-contact'`
- `AppNavigator.toEmergencyContact(productId: String)`

**参考文件**：
- `dali_cash/lib/features/certification/emergency_contact/emergency_contact_page.dart`
- `dali_cash/lib/features/certification/emergency_contact/emergency_contact_data.dart`

**估计工作量**：2-3 天

---

### 9. 创建银行卡绑定页
**文件位置**：新建 `lib/pages/bind_card_page.dart`

**页面功能**：
1. **UI 展示**
   - 顶部导航栏
   - 通道选择（如果有多个通道）：银行卡、电子钱包等
   - 动态表单字段（根据选中通道的配置渲染）
   - 底部提交按钮

2. **数据获取**
   - 调用 `CertificationRepository.getBankInfo(productId)`
   - 接口：`POST /outsmelled/tremor`
   - 返回格式：
     - `groups`：通道分组（银行卡/电子钱包）
     - 每个通道有 `available` 标识和 `maintenanceText` 提示
     - 每个通道有自己的动态字段配置

3. **字段渲染**
   - 复用动态表单引擎（类似个人信息页）
   - 常见字段：
     - 账户类型（accountType）
     - 账号（accountNumber）
     - 姓名（firstName, middleName, lastName）

4. **二次活体验证**（可选，根据通道要求）
   - 某些通道需要在提交前再次进行活体认证
   - 调用 `CertificationRepository.getFacePPToken`
   - 上传活体照片

5. **提交逻辑**
   - 调用 `CertificationRepository.submitBankCard`
   - 接口：`POST /outsmelled/mycelia`
   - 参数：`productId`、`accountType`、`accountNumber`、`firstName`、`middleName`、`lastName`
   - 成功后：`continueProductDetailFlow(productId)`
   - **注意**：接口可能返回 code `20000` 表示软失败，需要特殊处理

6. **账号变更场景**
   - 如果是修改账号而不是首次绑定
   - 调用 `POST /lutes/creasing` (changeOrderAccount)
   - 然后打开返回的 WebView URL

**路由配置**：
- `AppRoutes.bindCard = '/bind-card'`
- `AppNavigator.toBindCard(productId: String)`

**参考文件**：
- `dali_cash/lib/features/certification/bind_card/bind_card_page.dart`
- `dali_cash/lib/features/certification/bind_card/bind_card_data.dart`

**估计工作量**：3-4 天

---

## 🟡 P1 任务：重要功能

### 10. 完善 ProductApplicationFlow 的步骤路由
**文件位置**：`lib/core/product/product_application_flow.dart`

**当前状态**：
- ✅ 准入流程已完成
- ✅ DeepLink 解析已完成
- ❌ `_continueFromDetail` 方法中的所有 case 都是 TODO

**需要实现**：
- 将所有 `TODO` 替换为实际的导航调用
- 示例：
  ```dart
  case 'Outpulls':
    await AppNavigator.toIdentityType(productId: productId);
    break;
  
  case 'ViscosimeterDollop':
    await AppNavigator.toIdentityFace(productId: productId);
    break;
  
  // ... 其他 case
  ```

**估计工作量**：0.5 天

---

### 11. 添加风险上报接口调用
**文件位置**：`lib/data/repositories/report_repository.dart`

**当前状态**：
- ReportRepository 已存在
- 需要确认是否已有 `reportRisk` 方法

**需要实现**（如果没有）：
```dart
Future<ApiResponse<void>> reportRisk({
  required int scene,
  String? extra,
}) async {
  return _client.post(
    '/report/risk',  // 实际接口路径待确认
    params: {
      'scene': scene,
      if (extra != null) 'extra': extra,
    },
    parse: (_) => null,
  );
}
```

**场景编号**：
- `3` - 证件确认页提交后
- `4` - 活体认证完成后
- `5` - 个人信息提交后
- `6` - 工作信息提交后
- （紧急联系人和绑卡页是否需要上报，待确认）

**估计工作量**：0.5 天

---

### 12. 添加路由配置到 AppRouteGenerator
**文件位置**：`lib/core/navigation/app_route_generator.dart`

**需要添加的路由**：
1. `/identity-confirmation` → `IdentityConfirmationPage`
2. `/identity-face` → `IdentityFacePage`
3. `/personal-information` → `PersonalInformationPage`
4. `/work-information` → `WorkInformationPage`
5. `/emergency-contact` → `EmergencyContactPage`
6. `/bind-card` → `BindCardPage`

**示例代码**：
```dart
case AppRoutes.identityConfirmation:
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => IdentityConfirmationPage(
      productId: args.productId,
      cardType: args.cardType,
      recognizedInfo: args.recognizedInfo,
    ),
  );
```

**估计工作量**：0.5 天

---

### 13. 添加活体结果上报接口
**文件位置**：`lib/data/repositories/certification_repository.dart`

**需要添加**：
```dart
Future<ApiResponse<void>> reportLivenessResult({
  required String livenessId,
  required String license,
  required Map<String, dynamic> result,
}) async {
  return _client.post(
    '/lutes/adapting',  // 路径待确认
    params: {
      'feoffed': livenessId,
      'miscasts': license,
      'result': result,
    },
    parse: (_) => null,
  );
}
```

**估计工作量**：0.5 天

---

## 🟢 P2 任务：优化项

### 14. 添加认证流程防返回弹窗
**功能描述**：
- 用户在认证流程中按返回键时，弹窗提示："确定要放弃认证吗？"
- 类似 dali_cash 的 `certification_retention_guard.dart`

**实现方式**：
- 使用 `WillPopScope` 或 `PopScope` (Flutter 3.12+)
- 弹窗文案从 API 获取：`POST /lutes/weldor` (retentionDialog)

**估计工作量**：1 天

---

### 15. 添加每个页面的进度指示器
**功能描述**：
- 在页面顶部显示当前步骤进度（如 "2/6"）
- 或者使用横向进度条

**实现方式**：
- 根据 `nextStep.taskType` 计算当前步骤编号
- 总步骤数固定为 6（身份、活体、个人、工作、联系人、绑卡）

**估计工作量**：0.5 天

---

### 16. 优化证件上传页的图片预览
**功能描述**：
- 拍照/选择图片后，显示预览界面
- 允许用户重新拍摄或确认上传

**估计工作量**：1 天

---

### 17. 添加表单字段的自动保存
**功能描述**：
- 用户填写表单时，自动保存到本地
- 下次进入页面时恢复之前的输入
- 避免用户误退出后需要重新填写

**实现方式**：
- 使用 `SharedPreferences` 或 `Hive` 缓存表单数据
- 提交成功后清除缓存

**估计工作量**：1 天

---

### 18. 添加网络异常处理和重试机制
**功能描述**：
- 接口调用失败时，显示友好的错误提示
- 提供"重试"按钮
- 对于某些步骤（如图片上传），支持断点续传

**估计工作量**：1-2 天

---

## 📊 总体估计

### 开发时间线（按优先级）

#### 第一阶段：核心流程打通（P0）
- **任务 1-3**：证件上传 + 确认页 + 流程调度 = **5-6 天**
- **任务 4**：活体认证页 = **3-4 天**
- **任务 5-7**：动态表单 + 个人信息 + 工作信息 = **5-6 天**
- **任务 8**：紧急联系人页 = **2-3 天**
- **任务 9**：银行卡绑定页 = **3-4 天**

**小计**：约 **18-23 个工作日**

#### 第二阶段：完善功能（P1）
- **任务 10-13**：路由配置 + 风险上报 + 接口补充 = **2 天**

**小计**：约 **2 个工作日**

#### 第三阶段：体验优化（P2）
- **任务 14-18**：防返回弹窗 + 进度指示 + 预览 + 自动保存 + 异常处理 = **4-6 天**

**小计**：约 **4-6 个工作日**

### 总计
**完整开发周期**：约 **24-31 个工作日**（约 **5-6 周**）

---

## 🚀 推荐实施路径

### Sprint 1（第 1-2 周）
1. 证件上传功能实现 ✅
2. 证件确认页开发 ✅
3. continueProductDetailFlow 方法实现 ✅

**交付物**：用户可以完成证件上传和确认，流程能自动跳转到下一步

---

### Sprint 2（第 3 周）
4. 活体认证页开发 ✅
5. 共享动态表单引擎开发 ✅

**交付物**：用户可以完成活体认证，表单引擎可复用

---

### Sprint 3（第 4 周）
6. 个人信息页开发 ✅
7. 工作信息页开发 ✅
8. 紧急联系人页开发 ✅

**交付物**：用户可以填写个人信息、工作信息和紧急联系人

---

### Sprint 4（第 5 周）
9. 银行卡绑定页开发 ✅
10. 完善路由配置 ✅
11. 添加风险上报 ✅

**交付物**：完整的认证流程可以走通，从证件上传到银行卡绑定

---

### Sprint 5（第 6 周）
12. 体验优化（防返回弹窗、进度指示器等）✅
13. 异常处理和重试机制 ✅
14. 测试和 Bug 修复 ✅

**交付物**：稳定可发布的认证流程

---

## 📝 注意事项

### 1. 接口对接
- 所有接口路径需要与后端确认（当前文档中的路径来自 dali_cash，可能不完全匹配）
- 混淆字段名需要与后端保持一致
- 注意接口的加密/解密逻辑

### 2. 数据模型
- 需要为每个页面创建对应的数据模型类
- 参考 `lib/data/models/certification_data.dart` 的结构
- 使用 `freezed` 或类似工具生成不可变模型

### 3. 状态管理
- 建议使用 `riverpod` 管理页面状态
- 表单字段较多时，考虑使用 `form_builder` 或类似库

### 4. 原生集成
- 活体 SDK 需要原生代码集成（iOS/Android）
- 通讯录权限需要在 `Info.plist` 和 `AndroidManifest.xml` 中声明
- 相机/相册权限同样需要声明

### 5. 测试
- 每个页面完成后需要进行功能测试
- 重点测试：表单校验、网络异常、边界情况
- 建议编写 Widget 测试和集成测试

---

## 📖 参考资源

### 内部文档
- `dali_cash` 项目：`/Users/xios/Desktop/dali_cash`
- 内存中的架构记录：`/Users/xios/.zcode/cli/memories/projects/peso_shield-a1611883aa498ff9/memory/`

### 相关文件
- 产品申请流程：`lib/core/product/product_application_flow.dart`
- 认证接口定义：`lib/data/repositories/certification_repository.dart`
- 导航配置：`lib/core/navigation/app_navigator.dart`
- 路由生成器：`lib/core/navigation/app_route_generator.dart`

---

**最后更新**：2026-09-02
**维护者**：开发团队
**状态**：进行中
