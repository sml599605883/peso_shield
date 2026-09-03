import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/certification_data.dart' as model;
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';

class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState
    extends ConsumerState<PersonalInformationPage> {
  model.PersonalInfoData? _data;
  final _values = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  List<String>? _addresses;
  bool _loading = true;
  bool _submitting = false;
  bool _loadingAddresses = false;
  String? _error;

  static const _defaultPrompt =
      'Step 1 to fast cash! Upload ID for the express approval channel.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.getPersonalInfo(
        productId: widget.productId,
      );
      if (!response.isSuccess) throw Exception(response.message);
      if (!mounted) return;
      _disposeControllers();
      for (final field in response.data.fields) {
        _values[field.key] = field.initialSubmitValue;
        _controllers[field.key] = TextEditingController(
          text: field.initialDisplayValue,
        );
      }
      setState(() {
        _data = response.data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load information';
      });
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _submit() async {
    final fields = _data?.fields ?? const <model.PersonalInformationField>[];
    for (final field in fields) {
      if (field.isRequired && (_values[field.key] ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter ${field.title}')));
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.savePersonalInfo(
        productId: widget.productId,
        formData: _values,
      );
      if (!response.isSuccess) throw Exception(response.message);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed, please try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final prompt = _data?.tips.trim();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: DecoratedBox(
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
                          'Personal information',
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
                  message: prompt == null || prompt.isEmpty
                      ? _defaultPrompt
                      : prompt,
                ),
                Padding(
                  padding: layout.edgeInsets(left: 15, right: 15, top: 8),
                  child: Image.asset(
                    AppAssets.personalInformationProgress,
                    key: const Key('personalInformationProgress'),
                    width: double.infinity,
                    height: layout.px(18),
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(height: layout.px(12)),
                Expanded(child: _buildContent(layout)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: layout.edgeInsets(
              left: 56,
              right: 56,
              top: 10,
              bottom: 10,
            ),
            child: SizedBox(
              height: layout.px(50),
              child: ElevatedButton(
                key: const Key('personalInformationSubmit'),
                onPressed: _loading || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.coral,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: layout.radius(25),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        width: layout.px(20),
                        height: layout.px(20),
                        child: const CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit',
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

  Widget _buildContent(AppLayout layout) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _load, child: Text(_error!)),
      );
    }
    final fields = _data?.fields ?? const <model.PersonalInformationField>[];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(layout.px(16)),
        ),
      ),
      child: ListView.separated(
        padding: layout.edgeInsets(left: 20, top: 20, right: 20, bottom: 20),
        itemCount: fields.length,
        separatorBuilder: (_, _) => SizedBox(height: layout.px(14)),
        itemBuilder: (_, index) => _buildField(fields[index], layout),
      ),
    );
  }

  Widget _buildField(model.PersonalInformationField field, AppLayout layout) {
    final controller = _controllers[field.key]!;
    final selectable =
        field.control == model.PersonalInformationControl.selection ||
        field.control == model.PersonalInformationControl.address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.title,
          style: TextStyle(
            color: AppColors.personalInformationLabel,
            fontFamily: 'Helvetica',
            fontSize: layout.px(14),
          ),
        ),
        SizedBox(height: layout.px(7)),
        TextField(
          controller: controller,
          readOnly: selectable,
          keyboardType: field.isNumeric
              ? TextInputType.number
              : TextInputType.text,
          inputFormatters: field.isNumeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          onTap: selectable ? () => _selectField(field) : null,
          onChanged: (value) => _values[field.key] = value,
          decoration: InputDecoration(
            hintText: field.placeholder,
            hintStyle: TextStyle(
              color: AppColors.loginHint,
              fontSize: layout.px(14),
            ),
            suffixIcon: selectable
                ? _loadingAddresses &&
                          field.control ==
                              model.PersonalInformationControl.address
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: AppColors.loginHint,
                        )
                : null,
            contentPadding: layout.edgeInsets(
              left: 20,
              top: 13,
              right: 14,
              bottom: 13,
            ),
            enabledBorder: _fieldBorder(layout),
            focusedBorder: _fieldBorder(layout),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(AppLayout layout) => OutlineInputBorder(
    borderRadius: layout.radius(20),
    borderSide: const BorderSide(color: AppColors.personalInformationBorder),
  );

  Future<void> _selectField(model.PersonalInformationField field) async {
    switch (field.control) {
      case model.PersonalInformationControl.selection:
        await _pickOption(field);
      case model.PersonalInformationControl.address:
        await _pickAddress(field);
      case model.PersonalInformationControl.text:
      case model.PersonalInformationControl.unsupported:
        return;
    }
  }

  Future<void> _pickOption(model.PersonalInformationField field) async {
    final option = await showModalBottomSheet<model.PersonalInformationOption>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in field.options)
              ListTile(
                title: Text(option.label),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (option == null || !mounted) return;
    setState(() {
      _values[field.key] = option.value;
      _controllers[field.key]!.text = option.label;
    });
  }

  Future<void> _pickAddress(model.PersonalInformationField field) async {
    if (_loadingAddresses) return;
    setState(() => _loadingAddresses = true);
    try {
      _addresses ??= await _loadAddressChoices();
      if (!mounted) return;
      final address = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final address in _addresses!)
                ListTile(
                  title: Text(address),
                  onTap: () => Navigator.of(context).pop(address),
                ),
            ],
          ),
        ),
      );
      if (address != null && mounted) {
        setState(() {
          _values[field.key] = address;
          _controllers[field.key]!.text = address;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load address options')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<List<String>> _loadAddressChoices() async {
    final repository = await ref.read(certificationRepositoryProvider.future);
    final response = await repository.getAddressInit();
    if (!response.isSuccess) throw Exception(response.message);
    return _flattenAddressValues([
      response.data.provinces,
      response.data.cities,
      response.data.barangays,
    ]).toSet().toList(growable: false);
  }

  List<String> _flattenAddressValues(Object? value) {
    if (value is Map) {
      return value.values.expand(_flattenAddressValues).toList(growable: false);
    }
    if (value is List) {
      return value.expand(_flattenAddressValues).toList(growable: false);
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? const [] : [text];
  }
}
