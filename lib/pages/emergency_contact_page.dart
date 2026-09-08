import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/product/product_providers.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/certification_data.dart' as model;
import '../data/models/emergency_contact_data.dart';
import '../providers/repository_provider.dart';
import '../providers/report_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';
import 'widgets/personal_information_option_sheet.dart';

class EmergencyContactPage extends ConsumerStatefulWidget {
  const EmergencyContactPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<EmergencyContactPage> createState() =>
      _EmergencyContactPageState();
}

enum _LoadState { loading, content, empty, error }

class _EmergencyContactPageState extends ConsumerState<EmergencyContactPage> {
  static const _defaultPrompt =
      'Please provide your emergency contact information for identity verification.';

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  _LoadState _loadState = _LoadState.loading;
  List<_ContactEntry> _contacts = const [];
  String _prompt = _defaultPrompt;
  String _loadError = '';
  bool _isSubmitting = false;
  late final int _sceneStartTime;

  @override
  void initState() {
    super.initState();
    _sceneStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final busy = _loadState == _LoadState.loading || _isSubmitting;

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
                                    'Emergency Information',
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
                          IdentityUploadPrompt(message: _prompt),
                          SizedBox(height: layout.px(12)),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(layout.px(16)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(layout.px(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: layout.edgeInsets(left: 15, top: 20, right: 15),
              child: Image.asset(
                AppAssets.emergencyContactProgress,
                key: const Key('emergencyContactProgress'),
                width: double.infinity,
                height: layout.px(18),
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: layout.px(20)),
            Expanded(child: _buildFormContent(layout)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(AppLayout layout) {
    switch (_loadState) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.empty:
        return _Status(
          message: 'No emergency contacts available',
          onRetry: _load,
        );
      case _LoadState.error:
        return _Status(message: _loadError, onRetry: _load);
      case _LoadState.content:
        return ListView.builder(
          padding: EdgeInsets.only(bottom: layout.px(24)),
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            return Padding(
              padding: EdgeInsets.only(bottom: layout.px(18)),
              child: _ContactGroupView(
                layout: layout,
                index: index,
                contact: contact,
                onRelationshipTap: () => _selectRelationship(contact),
                onContactTap: () => _selectContact(contact),
              ),
            );
          },
        );
    }
  }

  Widget _buildFooter(AppLayout layout) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.white),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: layout.edgeInsets(left: 56, right: 56, top: 10, bottom: 10),
          child: SizedBox(
            height: layout.px(50),
            child: ElevatedButton(
              key: const Key('emergencyContactUpload'),
              onPressed: _loadState == _LoadState.content && !_isSubmitting
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.5),
                disabledForegroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: layout.radius(25)),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontFamily: 'Helvetica',
                  fontSize: layout.px(18),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
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
      final response = await repository.getContactInfo(
        productId: widget.productId,
      );
      if (!response.isSuccess) {
        throw Exception(response.message);
      }
      final data = response.data;
      final contacts = data.contacts.map(_ContactEntry.new).toList();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _prompt = data.prompt.isEmpty ? _defaultPrompt : data.prompt;
        _loadState = contacts.isEmpty ? _LoadState.empty : _LoadState.content;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _contacts = const [];
        _loadError = message.isEmpty ? 'Unable to load contacts' : message;
        _loadState = _LoadState.error;
      });
      ToastHelper.showError(message);
    }
  }

  Future<void> _selectRelationship(_ContactEntry contact) async {
    final options = contact.data.relationshipOptions
        .map(
          (option) => model.PersonalInformationOption(
            label: option.label,
            value: option.value,
          ),
        )
        .toList(growable: false);

    final selected = await showPersonalInformationOptionSheet(
      context: context,
      options: options,
      selectedValue: contact.relationshipValue,
    );

    if (selected == null || !mounted) return;
    setState(() {
      contact.relationshipValue = selected.value;
      contact.relationshipLabel = selected.label;
    });
  }

  Future<void> _selectContact(_ContactEntry contact) async {
    try {
      final selected = await _pickNativeContact();
      if (selected == null || !mounted) return;
      setState(() {
        contact.name = selected.name.trim();
        contact.phone = selected.phone.trim();
      });
    } catch (error) {
      if (mounted) ToastHelper.showError(error.toString());
    }
  }

  Future<_EmergencyPickedContact?> _pickNativeContact() async {
    final contact = await _contactPicker.selectContact();
    if (contact == null) return null;
    return _EmergencyPickedContact(
      name: (contact.fullName ?? '').trim(),
      phone: _primaryPhone(contact),
    );
  }

  String _primaryPhone(Contact contact) {
    final selected = (contact.selectedPhoneNumber ?? '').trim();
    if (selected.isNotEmpty) return selected;
    for (final phone in contact.phoneNumbers ?? const <String>[]) {
      if (phone.trim().isNotEmpty) return phone.trim();
    }
    return '';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (widget.productId.isEmpty) {
      ToastHelper.showError('Product information is unavailable');
      return;
    }

    setState(() => _isSubmitting = true);
    final loading = ToastHelper.showLoading();
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.saveContactInfo(
        productId: widget.productId,
        contacts: _contacts
            .map((contact) => contact.toJson())
            .toList(growable: false),
      );
      loading();
      if (!mounted) return;
      
      // 检查 API 响应状态
      if (!response.isSuccess) {
        ToastHelper.showError(response.message);
        return;
      }

      // Report risk scene
      final reportService = ref.read(reportServiceProvider);
      unawaited(reportService.reportRisk(
        productId: widget.productId,
        scene: '7',
        startedAtSeconds: _sceneStartTime,
      ));
      
      // 提交成功后，调用 continueProductDetailFlow 获取下一步
      final flow = await ref.read(productApplicationFlowProvider.future);
      if (mounted) {
        await flow.continueProductDetailFlow(
          context: context,
          productId: widget.productId,
        );
      }
    } catch (error) {
      loading();
      if (mounted) ToastHelper.showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ContactEntry {
  _ContactEntry(this.data)
    : relationshipValue = data.relationshipValue,
      relationshipLabel = data.relationshipLabel,
      name = data.name,
      phone = data.phone;

  final EmergencyContact data;
  String relationshipValue;
  String relationshipLabel;
  String name;
  String phone;

  Map<String, String> toJson() {
    return {
      'injure': phone.trim(),
      'cymenes': name.trim(),
      'briner': relationshipValue.trim(),
      'searchers': data.number,
    };
  }
}

class _EmergencyPickedContact {
  const _EmergencyPickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class _ContactGroupView extends StatelessWidget {
  const _ContactGroupView({
    required this.layout,
    required this.index,
    required this.contact,
    required this.onRelationshipTap,
    required this.onContactTap,
  });

  final AppLayout layout;
  final int index;
  final _ContactEntry contact;
  final VoidCallback onRelationshipTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.emergencyContactSection,
          padding: layout.edgeInsets(left: 20, top: 7, bottom: 8),
          child: Text(
            'Emergency Contacts - ${index + 1}',
            key: Key('emergencyContactGroupTitle_${contact.data.number}'),
            style: TextStyle(
              color: AppColors.identityText,
              fontFamily: 'Helvetica',
              fontSize: layout.px(14),
              fontWeight: FontWeight.w700,
              height: 17 / 14,
            ),
          ),
        ),
        SizedBox(height: layout.px(16)),
        Padding(
          padding: layout.edgeInsets(left: 20),
          child: _Label(layout: layout, text: 'Relationship'),
        ),
        SizedBox(height: layout.px(7)),
        _FieldBox(
          layout: layout,
          key: Key('emergencyContactRelationship_${contact.data.number}'),
          onTap: onRelationshipTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contact.relationshipLabel.isEmpty
                      ? 'Please select'
                      : contact.relationshipLabel,
                  style: _valueStyle(
                    layout: layout,
                    placeholder: contact.relationshipLabel.isEmpty,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: layout.px(18),
                color: AppColors.personalInformationLabel,
              ),
            ],
          ),
        ),
        SizedBox(height: layout.px(18)),
        Padding(
          padding: layout.edgeInsets(left: 20),
          child: _Label(layout: layout, text: 'City You Work'),
        ),
        SizedBox(height: layout.px(7)),
        _FieldBox(
          layout: layout,
          height: 80,
          key: Key('emergencyContactPicker_${contact.data.number}'),
          onTap: onContactTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: layout.edgeInsets(top: 8, bottom: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name.isEmpty
                            ? 'Please select contact'
                            : contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _valueStyle(
                          layout: layout,
                          placeholder: contact.name.isEmpty,
                        ),
                      ),
                      SizedBox(height: layout.px(8)),
                      Text(
                        contact.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _valueStyle(
                          layout: layout,
                          placeholder: contact.phone.isEmpty,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: layout.px(8)),
              Image.asset(
                AppAssets.emergencyContactPicker,
                width: layout.px(22),
                height: layout.px(22),
              ),
            ],
          ),
        ),
        SizedBox(height: layout.px(18)),
      ],
    );
  }

  static TextStyle _valueStyle({
    required AppLayout layout,
    bool placeholder = false,
  }) {
    return TextStyle(
      color: placeholder
          ? AppColors.personalInformationLabel
          : AppColors.identityText,
      fontFamily: 'Helvetica',
      fontSize: layout.px(14),
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.layout, required this.text});

  final AppLayout layout;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.personalInformationLabel,
        fontFamily: 'Helvetica',
        fontSize: layout.px(12),
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    super.key,
    required this.layout,
    required this.onTap,
    required this.child,
    this.height = 40,
  });

  final AppLayout layout;
  final VoidCallback onTap;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: layout.edgeInsets(left: 20, right: 20),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: layout.radius(20),
          side: const BorderSide(color: AppColors.personalInformationBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: layout.radius(20),
          child: SizedBox(
            height: layout.px(height),
            child: Padding(
              padding: layout.edgeInsets(left: 12, right: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.personalInformationLabel,
              fontSize: layout.px(14),
            ),
          ),
          SizedBox(height: layout.px(12)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
