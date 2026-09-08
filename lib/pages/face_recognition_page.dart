import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/face/face_liveness_bridge.dart';
import '../core/face/face_token_handler.dart';
import '../core/permissions/permission_helper.dart';
import '../core/product/product_providers.dart';
import '../core/report/peso_report_service.dart';
import '../core/ui/toast_helper.dart';
import '../providers/report_provider.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';

/// Face verification page with backend integration
class FaceRecognitionPage extends ConsumerStatefulWidget {
  const FaceRecognitionPage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<FaceRecognitionPage> createState() =>
      _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends ConsumerState<FaceRecognitionPage> {
  bool _isProcessing = false;
  late final int _sceneStartTime;

  @override
  void initState() {
    super.initState();
    _sceneStartTime = PesoReportService.nowSeconds();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final cachedPrompt = ref
        .watch(sessionStoreProvider)
        .productDetailFacePrompt;
    final prompt = cachedPrompt.isNotEmpty
        ? cachedPrompt
        : 'Step 1 to fast cash! Upload ID for the express approval channel.';

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
                  SizedBox(height: layout.px(16)),
                  IdentityUploadPrompt(message: prompt),
                  Image.asset(
                    AppAssets.faceRecognitionIllustration,
                    width: layout.px(335),
                    height: layout.px(414),
                    fit: BoxFit.fill,
                    semanticLabel: 'Face verification instructions',
                  ),
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
                key: const Key('face-recognition-submit'),
                onPressed: _isProcessing ? null : _startFaceVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.coral,
                  disabledForegroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: layout.radius(25),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Start Verification',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startFaceVerification() async {
    if (_isProcessing) return;

    // Step 1: Check camera permission
    final permissionStatus = await PermissionHelper.requestCameraPermission();
    if (!mounted) return;

    if (permissionStatus != CameraPermissionStatus.granted) {
      await PermissionHelper.showCameraPermissionDialog(context);
      return;
    }

    setState(() => _isProcessing = true);

    String? faceImagePath;
    try {
      // Step 2: Get orderNo from session
      final orderNo = ref.read(sessionStoreProvider).productDetailOrderNo;
      if (orderNo.isEmpty) {
        ToastHelper.showError('Order information not found');
        return;
      }

      // Step 3: Get FacePP token from backend
      final loading = ToastHelper.showLoading();
      final repository = await ref.read(certificationRepositoryProvider.future);
      final tokenResponse = await repository.getFacePPToken(
        orderNo: orderNo,
        type: 0,
      );

      loading();

      if (!mounted) return;

      if (!await handleFaceTokenResponse(
        context,
        response: tokenResponse,
        productId: widget.productId,
      )) {
        return;
      }

      final token = tokenResponse.data.token;

      // Step 4: Launch FacePP SDK for liveness detection
      final result = await FaceLivenessBridge.instance.start(token);
      unawaited(ref.read(reportServiceProvider).reportTrustDecisionResult(result));

      if (!result.success) {
        ToastHelper.showError(
          result.message.isNotEmpty
              ? result.message
              : 'Face verification was not completed',
        );
        return;
      }

      if (result.image.isEmpty || result.livenessId.isEmpty) {
        ToastHelper.showError('Face verification returned incomplete data');
        return;
      }

      // Step 5: Write face image to temporary file
      faceImagePath = await _writeFaceImage(result.image);

      // Step 6: Upload face image to backend
      final uploadLoading = ToastHelper.showLoading();
      await repository.uploadFaceLiveness(
        filePath: faceImagePath,
        license: token,
        livenessId: result.livenessId,
        livenessType: 0,
      );
      uploadLoading();

      // 上报人脸识别场景
      try {
        final reportService = ref.read(reportServiceProvider);
        unawaited(reportService.reportRisk(
          productId: widget.productId,
          scene: '4',
          startedAtSeconds: _sceneStartTime,
        ));
      } catch (_) {
        // 上报失败不影响业务
      }

      if (!mounted) return;

      // Step 7: Continue to next step
      await _handleVerificationSuccess(orderNo);
    } catch (error) {
      if (mounted) {
        ToastHelper.showError('Verification failed: $error');
      }
    } finally {
      // Clean up temporary face image file
      if (faceImagePath != null) {
        try {
          await File(faceImagePath).delete();
        } on FileSystemException {
          // Best-effort cleanup
        }
      }
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String> _writeFaceImage(String imageBase64) async {
    final normalized =
        imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
    final bytes = base64Decode(normalized);
    final file = File(
      '${Directory.systemTemp.path}/peso_shield_face_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _handleVerificationSuccess(String orderNo) async {
    try {
      // Continue to next step in product flow
      final flow = await ref.read(productApplicationFlowProvider.future);
      if (mounted) {
        await flow.continueProductDetailFlow(
          context: context,
          productId: widget.productId,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError('Failed to continue: $e');
      }
    }
  }
}
