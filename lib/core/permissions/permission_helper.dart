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
        title: const Text('Enable Camera to Continue'),
        content: const Text(
          "We can't complete identity verification without camera access. "
          'Enable the permission to continue your application securely.',
        ),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogCancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Now'),
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: AppColors.dialogConfirm),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openAppSettings();
            },
            isDefaultAction: true,
            child: const Text('Allow'),
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
            title: const Text('Location Required'),
            content: const Text(
              'System location is disabled. Enable it to authenticate your identity and satisfy core risk assessment.',
            ),
            actions: [
              CupertinoDialogAction(
                textStyle: TextStyle(color: AppColors.dialogCancel),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Skip'),
              ),
              CupertinoDialogAction(
                textStyle: TextStyle(color: AppColors.dialogConfirm),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                isDefaultAction: true,
                child: const Text('Enable Location Services'),
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
            title: const Text('Enable Location Permission'),
            content: const Text(
              'Without location, we can\'t authenticate your identity during credit assessment or support fraud prevention.',
            ),
            actions: [
              CupertinoDialogAction(
                textStyle: TextStyle(color: AppColors.dialogCancel),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not Now'),
              ),
              CupertinoDialogAction(
                textStyle: TextStyle(color: AppColors.dialogConfirm),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                isDefaultAction: true,
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show retry photo dialog when ID photo verification fails
  static Future<bool> showRetryPhotoDialog(
    BuildContext context,
  ) async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text("Let's Try a New Photo"),
            content: const Text(
              "That photo didn't quite work. No worries - just snap a new one with your ID well-lit and flat, or upload a clearer picture to finish verification.",
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
                child: const Text('Retake ID'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Camera permission status
enum CameraPermissionStatus { granted, denied, permanentlyDenied }
