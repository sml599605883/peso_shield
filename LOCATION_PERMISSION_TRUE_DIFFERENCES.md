# 定位权限实现的真实差异

## 核心差异总结

| 差异点 | dali_cash | peso_shield | 影响 |
|--------|-----------|-------------|------|
| **iOS 版本兼容** | ❌ 仅支持 iOS 14+ | ✅ 支持 iOS 13+ | **重要** |
| **authorizationStatus 调用** | 直接调用实例方法 | iOS 13 降级处理 | **关键** |
| **状态字符串返回** | 细粒度 | 合并 | 次要 |

## 详细差异

### 1. ⚠️ **iOS 版本兼容性差异（最重要）**

#### dali_cash（仅支持 iOS 14+）
```swift
// 直接调用实例方法，在 iOS 13 会崩溃
let status = manager.authorizationStatus  // iOS 14+ 才有
```

#### peso_shield（支持 iOS 13+）
```swift
// 兼容 iOS 13
let status: CLAuthorizationStatus
if #available(iOS 14.0, *) {
  status = manager.authorizationStatus  // iOS 14+ 用实例方法
} else {
  status = CLLocationManager.authorizationStatus()  // iOS 13 用类方法
}
```

**影响：**
- ✅ peso_shield 更严谨，支持更广泛的 iOS 版本
- ⚠️ dali_cash 在 iOS 13 设备上会崩溃

### 2. 📍 **所有使用 authorizationStatus 的地方**

peso_shield 在 **5 个位置** 都做了兼容处理：

#### 位置 1: `getReportLocation()` - 检查初始状态
```swift
// peso_shield (兼容)
let status: CLAuthorizationStatus
if #available(iOS 14.0, *) {
  status = manager.authorizationStatus
} else {
  status = CLLocationManager.authorizationStatus()
}
```

#### 位置 2: `requestLocationPermission()` - 请求前检查
```swift
// peso_shield (兼容)
let status: CLAuthorizationStatus
if #available(iOS 14.0, *) {
  status = manager.authorizationStatus
} else {
  status = CLLocationManager.authorizationStatus()
}
guard status == .notDetermined else { ... }
```

#### 位置 3: `locationManagerDidChangeAuthorization()` - 权限请求回调
```swift
// peso_shield (兼容)
if manager === locationPermissionManager {
  let status: CLAuthorizationStatus
  if #available(iOS 14.0, *) {
    status = manager.authorizationStatus
  } else {
    status = CLLocationManager.authorizationStatus()
  }
  ...
}
```

#### 位置 4: `locationManagerDidChangeAuthorization()` - 定位获取回调
```swift
// peso_shield (兼容)
guard locationResult != nil else { return }
let status: CLAuthorizationStatus
if #available(iOS 14.0, *) {
  status = manager.authorizationStatus
} else {
  status = CLLocationManager.authorizationStatus()
}
if status == .authorizedAlways || status == .authorizedWhenInUse { ... }
```

#### 位置 5: `locationManager(_:didUpdateLocations:)` - 定位成功
```swift
// peso_shield (兼容)
guard let location = locations.last else {
  let status: CLAuthorizationStatus
  if #available(iOS 14.0, *) {
    status = manager.authorizationStatus
  } else {
    status = CLLocationManager.authorizationStatus()
  }
  finishLocation(locationPayload(..., status: locationStatus(status)))
  return
}
```

#### 位置 6: `locationManager(_:didFailWithError:)` - 定位失败
```swift
// peso_shield (兼容)
func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
  let status: CLAuthorizationStatus
  if #available(iOS 14.0, *) {
    status = manager.authorizationStatus
  } else {
    status = CLLocationManager.authorizationStatus()
  }
  finishLocation(locationPayload(..., status: locationStatus(status)))
}
```

### 3. 🔍 **API 变更历史**

```swift
// iOS 13 及以前
CLLocationManager.authorizationStatus()  // 类方法（已废弃）

// iOS 14+
manager.authorizationStatus  // 实例属性（推荐）
```

## 结论

### peso_shield **更优**的地方

✅ **1. 更好的向后兼容**
- 支持 iOS 13 及更早版本
- 不会在旧系统上崩溃

✅ **2. 更严谨的实现**
- 在 **6 个位置** 都做了版本检查
- 完整覆盖所有使用场景

✅ **3. 代码质量**
- 明确声明变量类型 `CLAuthorizationStatus`
- 使用 `#available` 编译检查

### dali_cash 的问题

⚠️ **1. iOS 13 不兼容**
- 直接调用 `manager.authorizationStatus` 会崩溃
- 没有降级处理

⚠️ **2. 假设最低版本**
- 隐式假设部署目标是 iOS 14+
- 没有明确文档说明

## 建议

### 对于 peso_shield
✅ **当前实现是正确的，无需修改**
- 兼容性处理完善
- 所有位置都有降级逻辑

### 对于 dali_cash
⚠️ **建议添加版本检查**
- 如果需要支持 iOS 13，应该参考 peso_shield 的实现
- 或者明确设置 Deployment Target 为 iOS 14+

## 最终结论

**peso_shield 的定位权限实现比 dali_cash 更加完善和稳健！**

| 维度 | peso_shield | dali_cash |
|------|-------------|-----------|
| iOS 兼容性 | ✅ iOS 13+ | ⚠️ iOS 14+ only |
| 代码健壮性 | ✅ 完整降级 | ⚠️ 无降级 |
| 版本检查覆盖 | ✅ 6 处 | ❌ 0 处 |
| 生产就绪度 | ✅ 高 | ⚠️ 中 |

**peso_shield 不仅对齐了 dali_cash，而且在兼容性上做得更好！** 🎉
