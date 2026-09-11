import 'dart:async';

import 'package:flutter/material.dart';

import '../core/navigation/app_route_generator.dart';
import '../core/navigation/app_routes.dart';
import '../core/report/peso_report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_provider.dart';
import '../providers/repository_provider.dart';
import '../data/models/certification_data.dart';
import '../data/models/retention_popup_data.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/retention_popup_dialog.dart';

/// Static identity document selection shown before document capture.
class IdentityTypePage extends ConsumerStatefulWidget {
  const IdentityTypePage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<IdentityTypePage> createState() => _IdentityTypePageState();
}

class _IdentityTypePageState extends ConsumerState<IdentityTypePage> {
  bool _showOtherOptions = false;
  IdentityTypeList? _identityTypeList;
  late final int _sceneStartTime;
  RetentionPopupData? _retentionData;
  bool _isLoadingRetention = false;

  @override
  void initState() {
    super.initState();
    _sceneStartTime = PesoReportService.nowSeconds();
    _loadIdentityTypes();
  }

  Future<bool> _handleWillPop() async {
    // 如果正在加载挽留弹窗，阻止返回
    if (_isLoadingRetention) return false;

    // 如果已经加载过挽留数据且不需要展示，直接返回
    if (_retentionData != null && !_retentionData!.shouldShow) {
      return true;
    }

    // 首次返回时请求挽留弹窗配置
    if (_retentionData == null) {
      setState(() => _isLoadingRetention = true);
      try {
        final repository = await ref.read(certificationRepositoryProvider.future);
        final response = await repository.getRetentionPopup(
          productId: widget.productId,
          popupType: '0', // 0=身份认证页面
        );

        if (response.isSuccess && mounted) {
          _retentionData = response.data;
          
          // 如果需要展示挽留弹窗
          if (_retentionData!.shouldShow) {
            final shouldStay = await RetentionPopupDialog.show(
              context,
              _retentionData!,
            );
            setState(() => _isLoadingRetention = false);
            return !shouldStay; // true=离开, false=留下
          }
        }
      } catch (_) {
        // 请求失败，允许返回
      } finally {
        if (mounted) {
          setState(() => _isLoadingRetention = false);
        }
      }
    }

    return true;
  }

  Future<void> _loadIdentityTypes() async {
    final repository = await ref.read(certificationRepositoryProvider.future);
    final response = await repository.getIdentityTypeList(
      productId: widget.productId,
    );

    if (response.isSuccess && mounted) {
      setState(() {
        _identityTypeList = response.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);

    // 完全使用接口数据，没有则为空
    final options = _showOtherOptions
        ? (_identityTypeList?.otherIdTypes ?? [])
        : (_identityTypeList?.recommendedIdTypes ?? []);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                child: Column(
                  children: [
                    SizedBox(height: layout.px(21)),
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
                    SizedBox(height: layout.px(29)),
                    SizedBox(
                      height: layout.px(117),
                      child: Stack(
                        children: [
                          Positioned(
                            top: layout.px(14),
                            left: layout.px(20),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  layout.px(9),
                                  layout.px(5),
                                  layout.px(10),
                                  layout.px(6),
                                ),
                                child: Text(
                                  'Maximum Credit Amount',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontFamily: 'Helvetica',
                                    fontSize: layout.px(12),
                                    fontWeight: FontWeight.w300,
                                    height: 14 / 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: layout.px(76),
                            left: 0,
                            child: Container(
                              width: layout.px(226),
                              height: layout.px(24),
                              color: AppColors.identityHighlight,
                            ),
                          ),
                          Positioned(
                            top: layout.px(39),
                            left: layout.px(20),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.w700,
                                  height: 43 / 36,
                                ),
                                children: [
                                  TextSpan(
                                    text: '₱',
                                    style: TextStyle(fontSize: layout.px(36)),
                                  ),
                                  TextSpan(
                                    text: ' 60,000',
                                    style: TextStyle(fontSize: layout.px(50)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: layout.px(20),
                            child: Image.asset(
                              AppAssets.identityShieldIllustration,
                              width: layout.px(113),
                              height: layout.px(117),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: layout.px(7)),
                    _buildTabs(layout),
                    SizedBox(height: layout.px(7)),
                    _buildOptions(layout, options),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppLayout layout) {
    return Container(
      key: const Key('identity-tabs'),
      width: layout.px(336),
      height: layout.px(40),
      padding: EdgeInsets.all(layout.px(3)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab(layout, 'Recommended ID Type', !_showOtherOptions),
          ),
          Expanded(child: _tab(layout, 'Other Options', _showOtherOptions)),
        ],
      ),
    );
  }

  Widget _tab(AppLayout layout, String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _showOtherOptions = label == 'Other Options'),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.white,
          borderRadius: layout.radius(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.identityUnselected,
            fontFamily: 'Helvetica',
            fontSize: layout.px(12),
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(AppLayout layout, List<String> options) {
    return Container(
      margin: layout.edgeInsets(left: 20, right: 20),
      padding: EdgeInsets.all(layout.px(15)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.identityPanelEnd, AppColors.identityPanelStart],
        ),
        borderRadius: layout.radius(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.identityPanelStart.withValues(alpha: 0.45),
            blurRadius: layout.px(12),
            spreadRadius: layout.px(1),
            offset: Offset(0, layout.px(6)),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            _option(layout, options[index]),
            if (index < options.length - 1) SizedBox(height: layout.px(7)),
          ],
        ],
      ),
    );
  }

  Widget _option(AppLayout layout, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(layout.px(10)),
          topRight: Radius.circular(layout.px(100)),
          bottomRight: Radius.circular(layout.px(100)),
          bottomLeft: Radius.circular(layout.px(10)),
        ),
        onTap: () async {
          // 上报认证选择场景
          try {
            final reportService = ref.read(reportServiceProvider);
            unawaited(reportService.reportRisk(
              productId: widget.productId,
              scene: '2',
              startedAtSeconds: _sceneStartTime,
            ));
          } catch (_) {
            // 上报失败不影响业务
          }
          
          await Navigator.of(context).pushNamed(
            AppRoutes.identityUpload,
            arguments: IdentityUploadPageArguments(
              productId: widget.productId,
              cardType: label,
            ),
          );
        },
        child: Container(
          width: layout.px(301),
          height: layout.px(50),
          padding: EdgeInsets.symmetric(horizontal: layout.px(8)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(layout.px(10)),
              topRight: Radius.circular(layout.px(100)),
              bottomRight: Radius.circular(layout.px(100)),
              bottomLeft: Radius.circular(layout.px(10)),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                AppAssets.identityDocumentIcon,
                width: layout.px(21),
                height: layout.px(19),
              ),
              SizedBox(width: layout.px(15)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.identityText,
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(16),
                    height: 19 / 16,
                  ),
                ),
              ),
              Image.asset(
                AppAssets.identityOptionArrow,
                width: layout.px(20),
                height: layout.px(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
