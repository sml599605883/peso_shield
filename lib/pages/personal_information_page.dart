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
import 'widgets/personal_information_payday_sheet.dart';

enum InformationPageKind { personal, work }

class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key, required this.productId})
    : kind = InformationPageKind.personal;

  const PersonalInformationPage.work({super.key, required this.productId})
    : kind = InformationPageKind.work;

  final String productId;
  final InformationPageKind kind;

  bool get isWork => kind == InformationPageKind.work;

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

  static const _defaultPersonalPrompt =
      'Step 1 to fast cash! Upload ID for the express approval channel.';
  static const _defaultWorkPrompt =
      'Complete your work information for the express approval channel.';

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
      final data = await _loadInformation();
      if (!mounted) return;
      _disposeControllers();
      for (final field in data.fields) {
        _values[field.key] = field.initialSubmitValue;
        _controllers[field.key] = TextEditingController(
          text: field.initialDisplayValue,
        );
      }
      setState(() {
        _data = data;
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

  Future<model.PersonalInfoData> _loadInformation() async {
    final repository = await ref.read(certificationRepositoryProvider.future);
    if (widget.isWork) {
      final response = await repository.getWorkInfo(
        productId: widget.productId,
      );
      if (!response.isSuccess) throw Exception(response.message);
      return model.PersonalInfoData(
        fields: response.data.fields,
        tips: response.data.tips,
      );
    }

    final response = await repository.getPersonalInfo(
      productId: widget.productId,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data;
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
      final response = widget.isWork
          ? await repository.saveWorkInfo(
              productId: widget.productId,
              formData: _values,
            )
          : await repository.savePersonalInfo(
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
                            widget.isWork
                                ? 'Work Information'
                                : 'Personal information',
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
                        ? widget.isWork
                              ? _defaultWorkPrompt
                              : _defaultPersonalPrompt
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
                key: Key(
                  widget.isWork
                      ? 'workInformationSubmit'
                      : 'personalInformationSubmit',
                ),
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
              widget.isWork
                  ? AppAssets.workInformationProgress
                  : AppAssets.personalInformationProgress,
              key: Key(
                widget.isWork
                    ? 'workInformationProgress'
                    : 'personalInformationProgress',
              ),
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
    final canEdit = field.control == model.PersonalInformationControl.text;
    final canSelect =
        field.control == model.PersonalInformationControl.selection ||
        field.control == model.PersonalInformationControl.address;
    return PersonalInformationInputField(
      controller: controller,
      label: field.title,
      hintText: field.placeholder,
      readOnly: !canEdit,
      keyboardType: field.isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: field.isNumeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      onTap: canSelect ? () => _selectField(field) : null,
      onChanged: (value) => _values[field.key] = value,
      showTrailingArrow: canSelect,
    );
  }

  Future<void> _selectField(model.PersonalInformationField field) async {
    if (field.control == model.PersonalInformationControl.address) {
      await _pickAddress(field);
      return;
    }
    if (field.control != model.PersonalInformationControl.selection) return;
    if (widget.isWork && field.key.trim().toLowerCase() == 'overcrowds') {
      await _pickPayday(field);
      return;
    }
    if (field.options.any((option) => option.children.isNotEmpty)) {
      await _pickNestedOption(field);
      return;
    }
    await _pickOption(field);
  }

  Future<void> _pickPayday(model.PersonalInformationField field) async {
    final selection = await showPersonalInformationPaydaySheet(
      context: context,
      options: field.options,
      initialValue: _values[field.key],
    );
    if (selection == null || !mounted) return;
    setState(() {
      _values[field.key] = selection.submitValue;
      _controllers[field.key]!.text = selection.displayValue;
    });
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

  Future<void> _pickNestedOption(model.PersonalInformationField field) async {
    final parent = await showPersonalInformationOptionSheet(
      context: context,
      options: field.options,
    );
    if (parent == null || !mounted) return;
    if (parent.children.isEmpty) {
      setState(() {
        _values[field.key] = parent.value;
        _controllers[field.key]!.text = parent.label;
      });
      return;
    }

    final child = await showPersonalInformationOptionSheet(
      context: context,
      options: parent.children,
    );
    if (child == null || !mounted) return;
    setState(() {
      _values[field.key] = child.value;
      _controllers[field.key]!.text = '${parent.label}|${child.label}';
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
