import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/toast_helper.dart';
import '../../data/models/retention_popup_data.dart';
import '../../providers/repository_provider.dart';
import 'retention_popup_dialog.dart';

/// 认证项页面退出时的挽留弹窗逻辑。
///
/// 每次点击返回都会重新请求挽留弹窗配置；用户选择“继续认证”时留在当前页，
/// 选择“退出”或接口不可用时放行返回。
mixin RetentionPopupGuard<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// 当前认证项所属产品 ID。
  String get retentionProductId;

  /// 弹窗类型：0-身份认证，1-人脸，2-个人信息，3-工作，4-紧急联系人，5-确认用款。
  String get retentionPopupType;

  bool _loadingRetentionPopup = false;

  Future<bool> handleRetentionExit() async {
    if (_loadingRetentionPopup) return false;
    _loadingRetentionPopup = true;
    // 挽留弹窗接口返回前先展示 loading，避免点击返回后页面看起来无响应。
    final closeLoading = ToastHelper.showLoading();
    RetentionPopupData? popupData;
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.getRetentionPopup(
        productId: retentionProductId,
        popupType: retentionPopupType,
      );
      if (response.isSuccess) {
        popupData = response.data;
      }
    } catch (_) {
      // 请求失败不应阻塞返回流程。
    } finally {
      _loadingRetentionPopup = false;
      closeLoading();
    }
    if (!mounted || popupData == null || !popupData.shouldShow) return true;
    final shouldStay = await RetentionPopupDialog.show(context, popupData);
    return !shouldStay;
  }
}
