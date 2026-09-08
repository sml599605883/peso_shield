import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_coordinator.dart';
import '../../theme/app_colors.dart';

/// Helper methods for requesting permissions with user-friendly dialogs
class PermissionHelper {
  const PermissionHelper._();

  /// Request camera permission with proper handling of all states
  static Future<CameraPermissionStatus> requestCameraPermission() async {
    // Check current status first
    final currentStatus = await Permission.camera.status;

    // If already granted, return immediately
    if (currentStatus.isGranted) {
      return CameraPermissionStatus.granted;
    }

    // If permanently denied, don't request again
    if (currentStatus.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    // Request permission for other cases (denied/limited/restricted)
    final newStatus = await Permission.camera.request();

    if (newStatus.isGranted) {
      return CameraPermissionStatus.granted;
    } else if (newStatus.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    } else {
      return CameraPermissionStatus.denied;
    }
  }

  /// Show settings guidance when camera access is unavailable.
  static Future<void> showCameraPermissionDialog(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Allow Camera Access'),
        content: const Text(
          "We can't complete identity verification without camera access. "
          'Enable the permission to continue your application securely.',
        ),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogCancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogConfirm),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openAppSettings();
            },
            isDefaultAction: true,
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Request location permission for certification flow
  static Future<bool> requestCertificationLocation(BuildContext context) async {
    final decision = await PermissionCoordinator.instance
        .requestCertificationLocation();

    switch (decision) {
      case CertificationLocationDecision.granted:
        return true;

      case CertificationLocationDecision.denied:
        return false;

      case CertificationLocationDecision.serviceDisabled:
        if (context.mounted) {
          final openSettings = await _showLocationServiceDialog(context);
          if (openSettings) {
            await openAppSettings();
            return false;
          }
          return true;
        }
        return false;

      case CertificationLocationDecision.settingsRequired:
        if (context.mounted) {
          final openSettings = await _showLocationPermissionDialog(context);
          if (openSettings) {
            await openAppSettings();
            return false;
          }
          return true;
        }
        return false;
    }
  }

  static Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Turn On Location Services'),
            content: const Text(
              'To help us confirm your identity and safeguard your account '
              'against unauthorized access, please enable Location Services '
              'on your device to continue.',
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
                child: const Text('Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<bool> _showLocationPermissionDialog(
    BuildContext context,
  ) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Allow Location Access'),
            content: const Text(
              "We couldn't verify your location because permission is disabled. "
              'Please allow location access in your device settings to continue '
              'your application.',
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
                child: const Text('Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Camera permission status
enum CameraPermissionStatus { granted, denied, permanentlyDenied }
