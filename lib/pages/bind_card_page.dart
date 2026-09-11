import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/device/user_session.dart';
import '../core/face/face_liveness_bridge.dart';
import '../core/face/face_token_handler.dart';
import '../core/permissions/permission_helper.dart';
import '../core/network/api_response.dart';
import '../core/product/product_providers.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/bind_card_data.dart';
import '../data/models/certification_data.dart' as model;
import '../providers/repository_provider.dart';
import '../providers/report_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';
import 'widgets/personal_information_input_field.dart';
import 'widgets/personal_information_option_sheet.dart';

typedef BindCardSave =
    Future<ApiResponse<Map<String, dynamic>>> Function(
      String productId,
      String accountType,
      Map<String, String> fields,
      String livenessType,
      String livenessId,
      String image,
      String businessId,
      String license,
    );

class BindCardPage extends ConsumerStatefulWidget {
  const BindCardPage({
    required this.productId,
    super.key,
    this.orderNo = '',
    this.isAccountChange = false,
    this.save,
    this.continueFlow,
    this.requestCameraPermission,
    this.startLiveness,
    this.changeAccount,
  });

  final String productId;
  final String orderNo;
  final bool isAccountChange;
  final BindCardSave? save;
  final Future<void> Function()? continueFlow;
  final Future<PermissionStatus> Function()? requestCameraPermission;
  final Future<FaceLivenessResult> Function(String license)? startLiveness;
  final Future<String> Function(String orderNo, String bindId)? changeAccount;

  @override
  ConsumerState<BindCardPage> createState() => _BindCardPageState();
}

enum _LoadState { loading, content, empty, error }

class _BindCardPageState extends ConsumerState<BindCardPage> {
  _LoadState _loadState = _LoadState.loading;
  BindCardData? _data;
  String _loadError = '';
  String _selectedType = '';
  bool _submitting = false;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _values = {};
  final Set<String> _dismissedSuggestionKeys = {};
  String? _activeSuggestionKey;
  late final int _sceneStartTime;

  @override
  void initState() {
    super.initState();
    _sceneStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final busy = _loadState == _LoadState.loading || _submitting;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: !busy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !busy) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: busy,
              child: Scaffold(
                backgroundColor: AppColors.white,
                body: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppAssets.homeBackground),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
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
                                    'Work Information',
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
                          IdentityUploadPrompt(
                            message:
                                _data?.prompt ??
                                'Step 1 to fast cash! Upload ID for the express approval channel.',
                          ),
                          SizedBox(height: layout.px(4)),
                          Expanded(child: _buildContent(layout)),
                        ],
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: _buildFooter(layout),
              ),
            ),
            if (busy)
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLayout layout) {
    switch (_loadState) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.error:
        return _Status(message: _loadError, onRetry: _load);
      case _LoadState.empty:
        return const _Status(message: 'No payment methods available');
      case _LoadState.content:
        final data = _data!;
        final group = data.groups.firstWhere(
          (item) => item.type == _selectedType,
          orElse: () => data.groups.first,
        );
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(layout.px(30)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(layout.px(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: layout.edgeInsets(left: 15, top: 20, right: 15),
                  child: Image.asset(
                    AppAssets.bindCardProgress,
                    key: const Key('bindCardProgress'),
                    width: double.infinity,
                    height: layout.px(18),
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(height: layout.px(20)),
                _buildTabs(layout, data.groups),
                Expanded(child: _buildFields(layout, group)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildTabs(AppLayout layout, List<BindCardGroup> groups) {
    return Container(
      margin: layout.edgeInsets(left: 20, right: 20),
      height: layout.px(36),
      padding: EdgeInsets.all(layout.px(3)),
      decoration: BoxDecoration(
        color: AppColors.loginField,
        borderRadius: layout.radius(20),
      ),
      child: Row(
        children: [
          for (final group in groups)
            Expanded(
              child: GestureDetector(
                key: Key('bindCardTab_${group.type}'),
                onTap: () => _selectGroup(group.type),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: group.type == _selectedType
                        ? AppColors.coral
                        : Colors.transparent,
                    borderRadius: layout.radius(20),
                  ),
                  child: Text(
                    group.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: group.type == _selectedType
                          ? AppColors.white
                          : AppColors.identityUnselected,
                      fontFamily: 'Helvetica',
                      fontSize: layout.px(14),
                      fontWeight: group.type == _selectedType
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFields(AppLayout layout, BindCardGroup group) {
    return ListView.separated(
      padding: layout.edgeInsets(left: 20, right: 20, top: 22, bottom: 24),
      itemCount: group.fields.length,
      separatorBuilder: (_, _) => SizedBox(height: layout.px(14)),
      itemBuilder: (_, index) =>
          _buildField(layout, group, group.fields[index]),
    );
  }

  Widget _buildField(
    AppLayout layout,
    BindCardGroup group,
    BindCardField field,
  ) {
    final key = _fieldKey(group, field);
    final controller = _controllers[key]!;
    final selection = field.control == BindCardFieldControl.selection;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PersonalInformationInputField(
          key: Key('bindCardInput_${field.key}'),
          controller: controller,
          focusNode: _focusNodes[key],
          label: field.title,
          hintText: field.placeholder,
          readOnly: selection,
          keyboardType: field.numeric
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: field.numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          showTrailingArrow: selection,
          onTap: selection ? () => _pickOption(field, group) : null,
          onChanged: (value) => _values[key] = value,
        ),
        if (_activeSuggestionKey == key)
          Positioned(
            top: layout.px(-2),
            right: layout.px(24),
            child: _BindCardSuggestion(
              field: field,
              onApply: () => _applySuggestions(group),
              onClose: () => _dismissSuggestion(group, field),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(AppLayout layout) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.white),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: layout.edgeInsets(top: 10, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((_data?.bottomPrompt ?? '').isNotEmpty)
                Padding(
                  padding: layout.edgeInsets(bottom: 12),
                  child: SizedBox(
                    width: layout.px(312),
                    child: Text(
                      _data!.bottomPrompt,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.personalInformationOptionHint,
                        fontFamily: 'Helvetica',
                        fontSize: layout.px(14),
                        height: 18 / 14,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: layout.px(262),
                height: layout.px(50),
                child: ElevatedButton(
                  key: const Key('bindCardSubmit'),
                  onPressed: _loadState == _LoadState.content && !_submitting
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.coral,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.coral.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: layout.radius(25),
                    ),
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Helvetica',
                      fontSize: layout.px(18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loadState = _LoadState.loading;
      _loadError = '';
    });
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.getBindCardInfo(
        productId: widget.productId,
      );
      if (!response.isSuccess) throw Exception(response.message);
      final data = response.data;
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      for (final focusNode in _focusNodes.values) {
        focusNode.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      _values.clear();
      _dismissedSuggestionKeys.clear();
      _activeSuggestionKey = null;
      for (final group in data.groups) {
        for (final field in group.fields) {
          final key = _fieldKey(group, field);
          final controller = TextEditingController(text: field.initialValue);
          final focusNode = FocusNode();
          if (field.control == BindCardFieldControl.text) {
            controller.addListener(_updateActiveSuggestion);
            focusNode.addListener(_updateActiveSuggestion);
          }
          _controllers[key] = controller;
          _focusNodes[key] = focusNode;
          _values[key] = field.initialValue;
        }
      }
      if (!mounted) return;
      setState(() {
        _data = data;
        _selectedType = data.groups.isEmpty ? '' : data.groups.first.type;
        _loadState = data.groups.isEmpty
            ? _LoadState.empty
            : _LoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _loadError = message;
        _loadState = _LoadState.error;
      });
      ToastHelper.showError(message);
    }
  }

  Future<void> _pickOption(BindCardField field, BindCardGroup group) async {
    final current = _values[_fieldKey(group, field)] ?? '';
    final selected = await showPersonalInformationOptionSheet(
      context: context,
      options: field.options
          .map(
            (option) => model.PersonalInformationOption(
              label: option.label,
              value: option.value,
              logoUrl: option.logoUrl,
              showsHint: !option.available,
              hint: option.hint,
            ),
          )
          .toList(growable: false),
      selectedValue: current,
    );
    if (selected == null || !mounted) return;
    final key = _fieldKey(group, field);
    setState(() {
      _values[key] = selected.value;
      _controllers[key]!.text = selected.label;
    });
  }

  void _updateActiveSuggestion() {
    if (!mounted) return;
    final data = _data;
    if (data == null || data.groups.isEmpty) return;

    for (final group in data.groups) {
      for (final field in group.fields) {
        if (field.control != BindCardFieldControl.text) continue;
        final key = _fieldKey(group, field);
        if (_controllers[key]?.text.trim().isNotEmpty == true) {
          _dismissedSuggestionKeys.remove(key);
        }
      }
    }

    String? nextKey;
    final group = data.groups.firstWhere(
      (item) => item.type == _selectedType,
      orElse: () => data.groups.first,
    );
    for (final field in group.fields) {
      if (field.control != BindCardFieldControl.text) continue;
      final key = _fieldKey(group, field);
      if (_focusNodes[key]?.hasFocus != true ||
          _controllers[key]!.text.trim().isNotEmpty ||
          field.suggestedValue.isEmpty ||
          _dismissedSuggestionKeys.contains(key)) {
        continue;
      }
      nextKey = key;
      break;
    }
    if (_activeSuggestionKey != nextKey) {
      setState(() => _activeSuggestionKey = nextKey);
    }
  }

  void _dismissSuggestion(BindCardGroup group, BindCardField field) {
    final key = _fieldKey(group, field);
    setState(() {
      _dismissedSuggestionKeys.add(key);
      _activeSuggestionKey = null;
    });
  }

  void _applySuggestions(BindCardGroup group) {
    FocusManager.instance.primaryFocus?.unfocus();
    for (final field in group.fields) {
      if (field.control != BindCardFieldControl.text) continue;
      final key = _fieldKey(group, field);
      final suggestion = field.suggestedValue.trim();
      if (_controllers[key]!.text.trim().isEmpty && suggestion.isNotEmpty) {
        _controllers[key]!.text = suggestion;
        _values[key] = suggestion;
      }
    }
    if (mounted) setState(() => _activeSuggestionKey = null);
  }

  void _selectGroup(String groupType) {
    if (_selectedType == groupType) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedType = groupType;
      _activeSuggestionKey = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting || _data == null) return;
    final group = _data!.groups.firstWhere(
      (item) => item.type == _selectedType,
      orElse: () => _data!.groups.first,
    );
    final fields = <String, String>{};
    for (final field in group.fields) {
      final value = (_values[_fieldKey(group, field)] ?? '').trim();
      if (field.required && value.isEmpty) {
        ToastHelper.showError('${field.title} is required');
        return;
      }
      fields[field.key] = value;
    }
    final account = fields['cardNo'];
    final confirmation = fields['confirmCardNo'];
    if (account != null && confirmation != null && account != confirmation) {
      ToastHelper.showError('Account numbers do not match');
      return;
    }
    setState(() => _submitting = true);
    final loading = ToastHelper.showLoading();
    try {
      var response = await _save(group.type, fields);
      while (response.code == 20000) {
        loading();
        if (mounted) setState(() => _submitting = false);
        final shouldRetry = await PermissionHelper.showRetryPhotoDialog(context);
        if (!mounted) return;
        if (!shouldRetry) {
          // User cancelled
          return;
        }
        // User chose to retry, continue with liveness check
        setState(() => _submitting = true);
        ToastHelper.showLoading();
        final livenessResponse = await _completeLiveness(group.type, fields);
        if (livenessResponse == null) return;
        response = livenessResponse;
      }
      if (!mounted) return;
      if (!response.isSuccess) {
        ToastHelper.showError(
          response.message.isEmpty
              ? 'Unable to bind account'
              : response.message,
        );
        return;
      }
      if (widget.isAccountChange) {
        final bindId = response.data['retraction']?.toString() ?? '';
        if (widget.orderNo.isEmpty || bindId.isEmpty) {
          ToastHelper.showError('Missing account change information');
          return;
        }
        final url = await (widget.changeAccount ?? _changeAccount)(
          widget.orderNo,
          bindId,
        );
        if (url.isEmpty) ToastHelper.showError('Missing account change result');
        return;
      }

      // Report risk scene
      final reportService = ref.read(reportServiceProvider);
      unawaited(
        reportService.reportRisk(
          productId: widget.productId,
          scene: '8',
          startedAtSeconds: _sceneStartTime,
        ),
      );

      await (widget.continueFlow ?? _continue)();
    } catch (error) {
      if (mounted) ToastHelper.showError(error.toString());
    } finally {
      loading();
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> _save(
    String type,
    Map<String, String> fields,
  ) {
    if (widget.save != null) {
      return widget.save!(widget.productId, type, fields, '', '', '', '', '');
    }
    return ref
        .read(certificationRepositoryProvider.future)
        .then(
          (repository) => repository.submitBindCard(
            productId: widget.productId,
            accountType: type,
            fields: fields,
          ),
        );
  }

  Future<ApiResponse<Map<String, dynamic>>?> _completeLiveness(
    String type,
    Map<String, String> fields,
  ) async {
    final permission =
        await (widget.requestCameraPermission ??
            () => Permission.camera.request())();
    if (!mounted) return null;
    if (permission != PermissionStatus.granted) {
      ToastHelper.hideLoading();
      await PermissionHelper.showCameraPermissionDialog(context);
      return null;
    }
    final repository = await ref.read(certificationRepositoryProvider.future);
    final orderNo = widget.orderNo.isNotEmpty
        ? widget.orderNo
        : ref.read(sessionStoreProvider).productDetailOrderNo;
    final token = await repository.getFacePPToken(orderNo: orderNo, type: 1);
    if (!mounted) return null;
    if (!await handleFaceTokenResponse(
      context,
      response: token,
      productId: widget.productId,
    )) {
      return null;
    }
    final result =
        await (widget.startLiveness ?? FaceLivenessBridge.instance.start)(
          token.data.token,
        );
    unawaited(
      ref.read(reportServiceProvider).reportTrustDecisionResult(result),
    );
    if (!result.success || result.livenessId.isEmpty) {
      throw Exception(
        result.message.isEmpty
            ? 'Liveness verification failed'
            : result.message,
      );
    }
    if (widget.save != null) {
      return widget.save!(
        widget.productId,
        type,
        fields,
        '7',
        result.livenessId,
        result.image,
        '',
        token.data.token,
      );
    }
    return repository.submitBindCard(
      productId: widget.productId,
      accountType: type,
      fields: fields,
      livenessType: '7',
      livenessId: result.livenessId,
      image: result.image,
      license: token.data.token,
    );
  }

  Future<void> _continue() async {
    final flow = await ref.read(productApplicationFlowProvider.future);
    if (mounted) {
      await flow.continueProductDetailFlow(
        context: context,
        productId: widget.productId,
      );
    }
  }

  Future<String> _changeAccount(String orderNo, String bindId) async {
    final repository = await ref.read(certificationRepositoryProvider.future);
    final response = await repository.changeBindCard(
      orderNo: orderNo,
      bindId: bindId,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data;
  }

  String _fieldKey(BindCardGroup group, BindCardField field) =>
      '${group.type}:${field.key}';
}

class _BindCardSuggestion extends StatelessWidget {
  const _BindCardSuggestion({
    required this.field,
    required this.onApply,
    required this.onClose,
  });

  final BindCardField field;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return GestureDetector(
      key: Key('bindCardSuggestion_${field.key}'),
      behavior: HitTestBehavior.opaque,
      onTap: onApply,
      child: SizedBox(
        width: layout.px(104),
        height: layout.px(40),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.bindCardSuggestionBackground,
                key: Key('bindCardSuggestionBackground_${field.key}'),
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: layout.px(13),
              top: layout.px(7),
              right: layout.px(24),
              child: Text(
                field.suggestedValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontFamily: 'PingFang SC',
                  fontSize: layout.px(16),
                  fontWeight: FontWeight.w600,
                  height: 20 / 16,
                ),
              ),
            ),
            Positioned(
              top: layout.px(4),
              right: layout.px(2),
              child: GestureDetector(
                key: Key('bindCardSuggestionClose_${field.key}'),
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: SizedBox(
                  width: layout.px(24),
                  height: layout.px(24),
                  child: Center(
                    child: Image.asset(
                      AppAssets.bindCardSuggestionClose,
                      width: layout.px(12),
                      height: layout.px(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
