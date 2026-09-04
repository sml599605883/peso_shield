import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ui/toast_helper.dart';
import '../data/models/certification_data.dart' as model;
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';
import 'widgets/personal_information_address_sheet.dart';
import 'widgets/personal_information_input_field.dart';
import 'widgets/personal_information_option_sheet.dart';

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
  List<model.PersonalAddressNode>? _addressNodes;
  bool _loading = true;
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
    ToastHelper.showLoading();
    try {
      final repository = await ref.read(certificationRepositoryProvider.future);
      final response = await repository.savePersonalInfo(
        productId: widget.productId,
        formData: _values,
      );
      ToastHelper.hideLoading();
      if (!mounted) return;

      if (!response.isSuccess) {
        ToastHelper.showError(response.message);
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ToastHelper.hideLoading();
      if (mounted) {
        ToastHelper.showError('Submission failed, please try again');
      }
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
                  SizedBox(height: layout.px(12)),
                  Expanded(child: _buildContent(layout)),
                ],
              ),
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
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.coral,
                  elevation: 0,
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
          ),
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
      child: Column(
        children: [
          Padding(
            padding: layout.edgeInsets(left: 15, top: 20, right: 15),
            child: Image.asset(
              AppAssets.personalInformationProgress,
              key: const Key('personalInformationProgress'),
              width: double.infinity,
              height: layout.px(18),
              fit: BoxFit.fill,
            ),
          ),
          SizedBox(height: layout.px(20)),
          Expanded(child: _buildFormContent(layout)),
        ],
      ),
    );
  }

  Widget _buildFormContent(AppLayout layout) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _load, child: Text(_error!)),
      );
    }
    final fields = _data?.fields ?? const <model.PersonalInformationField>[];
    return ListView.separated(
      padding: layout.edgeInsets(left: 20, right: 20, bottom: 20),
      itemCount: fields.length,
      separatorBuilder: (_, _) => SizedBox(height: layout.px(14)),
      itemBuilder: (_, index) => _buildField(fields[index]),
    );
  }

  Widget _buildField(model.PersonalInformationField field) {
    final controller = _controllers[field.key]!;
    final hasTrailingArrow =
        field.controlType.toLowerCase() != 'empathisedwombiest';
    final canEdit = !hasTrailingArrow;
    return PersonalInformationInputField(
      controller: controller,
      label: field.title,
      hintText: field.placeholder,
      readOnly: !canEdit,
      keyboardType: field.isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: field.isNumeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onTap: !canEdit ? () => _selectField(field) : null,
      onChanged: (value) => _values[field.key] = value,
      showTrailingArrow: hasTrailingArrow,
    );
  }

  Future<void> _selectField(model.PersonalInformationField field) async {
    if (field.controlType.toLowerCase() == 'empathisedwombiest') return;
    if (field.control == model.PersonalInformationControl.address) {
      await _pickAddress(field);
      return;
    }
    await _pickOption(field);
  }

  Future<void> _pickOption(model.PersonalInformationField field) async {
    final option = await showPersonalInformationOptionSheet(
      context: context,
      options: field.options,
      selectedValue: _values[field.key],
    );
    if (option == null || !mounted) return;
    setState(() {
      _values[field.key] = option.value;
      _controllers[field.key]!.text = option.label;
    });
  }

  Future<void> _pickAddress(model.PersonalInformationField field) async {
    final cancel = ToastHelper.showLoading();
    try {
      _addressNodes ??= await _loadAddressChoices();
      cancel();
      if (!mounted) return;
      final address = await showPersonalInformationAddressSheet(
        context: context,
        nodes: _addressNodes!,
      );
      if (address != null && mounted) {
        setState(() {
          _values[field.key] = address;
          _controllers[field.key]!.text = address;
        });
      }
    } catch (_) {
      cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load address options')),
        );
      }
    }
  }

  Future<List<model.PersonalAddressNode>> _loadAddressChoices() async {
    final repository = await ref.read(certificationRepositoryProvider.future);
    final response = await repository.getAddressInit();
    if (!response.isSuccess) throw Exception(response.message);
    return response.data.nodes;
  }
}
