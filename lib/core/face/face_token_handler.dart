import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../data/models/face_token_result.dart';
import '../navigation/app_navigator.dart';
import '../network/api_response.dart';
import '../ui/toast_helper.dart';
import '../../theme/app_colors.dart';

Future<bool> handleFaceTokenResponse(
  BuildContext context, {
  required ApiResponse<FaceTokenResult> response,
  required String productId,
}) async {
  final result = response.data;
  if (response.isSuccess &&
      result.resultCode == 200 &&
      result.token.trim().isNotEmpty) {
    return true;
  }

  ToastHelper.hideLoading();
  if (!context.mounted) return false;
  if (response.isSuccess && result.resultCode == 400) {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Upload Your ID Again'),
        content: const Text(
          'Please select your ID type and upload your ID again to continue verification.',
        ),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogCancel),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogConfirm),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            isDefaultAction: true,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(AppNavigator.toIdentityType(productId: productId));
    }
    return false;
  }

  ToastHelper.showError(
    response.isSuccess && result.error.trim().isNotEmpty
        ? result.error
        : response.message.isNotEmpty && !response.isSuccess
        ? response.message
        : 'Failed to get verification token',
  );
  return false;
}
