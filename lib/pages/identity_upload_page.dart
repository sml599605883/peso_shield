import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';
import 'widgets/identity_upload_method_dialog.dart';
import 'widgets/identity_upload_services.dart';

/// Camera permission status
enum CameraPermissionStatus { granted, denied, permanentlyDenied }

/// ID upload page with camera/album integration and OCR upload
class IdentityUploadPage extends ConsumerStatefulWidget {
  const IdentityUploadPage({
    required this.productId,
    required this.cardType,
    super.key,
  });

  final String productId;
  final String cardType;

  /// 接口未下发 linocut 文案时的兜底展示。
  static const defaultPrompt =
      'Step 1 to fast cash! Upload ID for the express approval channel.';

  @override
  ConsumerState<IdentityUploadPage> createState() => _IdentityUploadPageState();
}

class _IdentityUploadPageState extends ConsumerState<IdentityUploadPage> {
  late final IdentityUploadImagePicker _imagePicker =
      DefaultIdentityUploadImagePicker();
  late final IdentityUploadImageCompressor _imageCompressor =
      DefaultIdentityUploadImageCompressor();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);

    // 优先使用产品详情缓存的 linocut 文案，为空时兜底
    final cachedPrompt = ref.watch(sessionStoreProvider).productDetailPrompt;
    final prompt = cachedPrompt.isNotEmpty
        ? cachedPrompt
        : IdentityUploadPage.defaultPrompt;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeBackground),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: layout.edgeInsets(bottom: 20),
              child: Column(
                children: [
                  SizedBox(height: layout.px(16)),
                  SizedBox(
                    height: layout.px(24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: layout.px(20),
                          child: const AppBackButton(),
                        ),
                        Center(
                          child: Text(
                            'Identity verification',
                            style: TextStyle(
                              color: AppColors.black,
                              fontFamily: 'Helvetica',
                              fontSize: layout.px(20),
                              fontWeight: FontWeight.w700,
                              height: 24 / 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: layout.px(33)),
                  IdentityUploadPrompt(message: prompt),
                  Image.asset(
                    AppAssets.identityUploadDemo,
                    width: layout.px(355),
                    height: layout.px(441),
                    fit: BoxFit.fill,
                    semanticLabel: 'Identity upload instructions',
                  ),
                  SizedBox(height: layout.px(14)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: layout.edgeInsets(left: 56, right: 56, bottom: 10),
            child: SizedBox(
              height: layout.px(50),
              child: ElevatedButton(
                key: const Key('identity-upload-submit'),
                onPressed: _isUploading
                    ? null
                    : () => _showIdentityUploadMethodDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: layout.radius(25),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(18),
                    fontWeight: FontWeight.w700,
                    height: 22 / 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showIdentityUploadMethodDialog(BuildContext context) async {
    final selectedMethod = await showGeneralDialog<IdentityUploadMethod>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close upload method selector',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const Align(
        alignment: Alignment.bottomCenter,
        child: IdentityUploadMethodDialog(),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final position = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        return SlideTransition(position: position, child: child);
      },
    );

    if (selectedMethod == null || !mounted) return;

    // Request camera permission if photograph is selected
    if (selectedMethod == IdentityUploadMethod.photograph) {
      final permissionResult = await _requestCameraPermission();

      if (permissionResult == CameraPermissionStatus.denied) {
        // 临时拒绝，用户下次还能看到权限弹窗，只显示轻提示
        if (mounted) {
          BotToast.showText(
            text: 'Camera permission is required to take photos',
          );
        }
        return;
      }

      if (permissionResult == CameraPermissionStatus.permanentlyDenied) {
        // 永久拒绝，必须去设置，显示引导对话框
        if (mounted) {
          await _showCameraPermissionDialog();
        }
        return;
      }
    }

    // Pick, compress and upload image
    await _pickCompressAndUpload(selectedMethod);
  }

  Future<CameraPermissionStatus> _requestCameraPermission() async {
    // 先检查当前状态
    final currentStatus = await Permission.camera.status;

    // 如果已授权，直接返回
    if (currentStatus.isGranted) {
      return CameraPermissionStatus.granted;
    }

    // 如果已永久拒绝，不要再请求
    if (currentStatus.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    // 其他情况（denied/limited/restricted）请求权限
    final newStatus = await Permission.camera.request();

    if (newStatus.isGranted) {
      return CameraPermissionStatus.granted;
    } else if (newStatus.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    } else {
      return CameraPermissionStatus.denied;
    }
  }

  Future<void> _showCameraPermissionDialog() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Allow Camera Access'),
        content: const Text(
          "We can't complete identity verification without camera access. Enable the permission to continue your application securely.",
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
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

  Future<void> _pickCompressAndUpload(IdentityUploadMethod method) async {
    final loading = BotToast.showLoading();
    try {
      // Step 1: Pick image from camera or album
      final String? filePath;
      if (method == IdentityUploadMethod.photograph) {
        filePath = await _imagePicker.pickFromCamera();
      } else {
        filePath = await _imagePicker.pickFromAlbum();
      }

      if (filePath == null || filePath.isEmpty) {
        loading();
        return;
      }

      // Step 2: Compress image to <= 500KB
      final compressedPath = await _imageCompressor.compressToLimit(filePath);
      if (compressedPath == null || compressedPath.isEmpty) {
        loading();
        BotToast.showText(text: 'Image compression failed');
        return;
      }

      // Step 3: Upload image and get OCR result
      await _uploadImage(compressedPath, method);
      loading();
    } catch (error) {
      loading();
      BotToast.showText(text: 'Upload failed: ${error.toString()}');
    }
  }

  Future<void> _uploadImage(
    String filePath,
    IdentityUploadMethod method,
  ) async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      // Upload the compressed file as multipart/form-data.
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.uploadImage(
        filePath: filePath,
        imageType: widget.cardType,
        imageSource: method == IdentityUploadMethod.photoAlbum ? '1' : '2',
      );

      if (!mounted) return;

      if (response.isSuccess) {
        // Close the upload spinner before presenting the next route. The
        // navigation future completes only when the confirmation page pops.
        unawaited(
          AppNavigator.toIdentityConfirmation(
            productId: widget.productId,
            cardType: widget.cardType,
            recognizedInfo: response.data,
          ),
        );
      } else {
        BotToast.showText(
          text: response.message.isNotEmpty
              ? response.message
              : 'Upload failed',
        );
      }
    } catch (error) {
      if (mounted) {
        BotToast.showText(text: 'Upload error: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
