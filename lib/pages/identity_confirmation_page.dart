import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/product/product_providers.dart';
import '../core/device/user_session.dart';
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import 'widgets/identity_upload_prompt.dart';

class IdentityConfirmationPage extends ConsumerStatefulWidget {
  const IdentityConfirmationPage({
    required this.productId,
    required this.cardType,
    this.recognizedInfo,
    super.key,
  });
  final String productId;
  final String cardType;
  final Map<String, dynamic>? recognizedInfo;
  @override
  ConsumerState<IdentityConfirmationPage> createState() =>
      _IdentityConfirmationPageState();
}

class _IdentityConfirmationPageState
    extends ConsumerState<IdentityConfirmationPage> {
  late final TextEditingController _name;
  late final TextEditingController _id;
  late final TextEditingController _birth;
  bool _submitting = false;

  String _value(String key, [String fallback = '']) {
    final source = widget.recognizedInfo ?? const <String, dynamic>{};
    final value = source[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
    return fallback;
  }

  String get _imageUrl => _value('mycelia');

  String _prompt() {
    final value = ref
        .read(sessionStoreProvider)
        .productDetailIdentitySuccessPrompt;
    return value.trim().isEmpty
        ? 'Check your information before submitting.'
        : value;
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _value('cymenes'));
    _id = TextEditingController(text: _value('neighborhood'));
    _birth = TextEditingController(text: _normalizeBirth(_value('sudaries')));
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _birth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLayout.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
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
                SizedBox(height: l.px(16)),
                SizedBox(
                  height: l.px(24),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          'Identity verification',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: l.edgeInsets(bottom: 20),
                    child: Column(
                      children: [
                        SizedBox(height: l.px(16)),
                        IdentityUploadPrompt(message: _prompt()),
                        Container(
                          width: double.infinity,
                          height: l.px(222),
                          margin: l.edgeInsets(left: 20, right: 20),
                          padding: l.edgeInsets(
                            left: 15,
                            right: 15,
                            top: 15,
                            bottom: 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.identityPanelEnd,
                                AppColors.identityPanelStart,
                              ],
                            ),
                            borderRadius: l.radius(10),
                          ),
                          child: Container(
                            height: l.px(192),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(202, 230, 227, 1),
                              borderRadius: l.radius(10),
                              border: Border.all(
                                color: const Color.fromRGBO(199, 199, 199, 1),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _imageUrl.isEmpty
                                ? const SizedBox.shrink()
                                : Image.network(_imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: l.px(17)),
                        Container(
                          padding: l.edgeInsets(left: 20, right: 20),
                          child: Column(
                            children: [
                              _field(l, 'Full Name', _name),
                              _field(l, 'ID No.', _id),
                              _field(
                                l,
                                'Date of Birth',
                                _birth,
                                readOnly: true,
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: l.edgeInsets(left: 56, right: 56, bottom: 10),
            child: SizedBox(
              height: l.px(50),
              child: ElevatedButton(
                key: const Key('identity-confirmation-submit'),
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: l.radius(25)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: l.px(18),
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

  Widget _field(
    AppLayout l,
    String label,
    TextEditingController c, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) => Padding(
    padding: l.edgeInsets(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color.fromRGBO(153, 153, 153, 1),
            fontSize: l.px(12),
          ),
        ),
        SizedBox(height: l.px(7)),
        SizedBox(
          height: l.px(40),
          child: TextField(
            controller: c,
            readOnly: readOnly,
            onTap: onTap,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            // textAlign: TextAlign.right,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              isDense: true,
              // contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: l.radius(20),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(236, 237, 237, 1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: l.radius(20),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(236, 237, 237, 1),
                ),
              ),
            ),
            style: TextStyle(
              color: AppColors.identityText,
              fontFamily: 'Helvetica',
              fontSize: l.px(14),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final d = await showGeneralDialog<DateTime>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close date picker',
        barrierColor: const Color.fromRGBO(0, 0, 0, 0.4),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _IdentityBirthdaySheet(initialDate: _parseBirth()),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 220),
      );
      if (d != null) {
        _birth.text =
            '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
      }
    } finally {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  DateTime _parseBirth() {
    return _parseBirthValue(_birth.text) ?? DateTime(1997, 7, 15);
  }

  String _normalizeBirth(String value) {
    final date = _parseBirthValue(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  DateTime? _parseBirthValue(String value) {
    final normalized = value.trim();
    final serverParts = normalized.split('/');
    if (serverParts.length == 3) {
      final year = int.tryParse(serverParts[0]);
      final month = int.tryParse(serverParts[1]);
      final day = int.tryParse(serverParts[2]);
      if (year != null && month != null && day != null) {
        return _validDate(year, month, day);
      }
    }

    final displayParts = normalized.split('-');
    if (displayParts.length == 3) {
      final day = int.tryParse(displayParts[0]);
      final month = int.tryParse(displayParts[1]);
      final year = int.tryParse(displayParts[2]);
      if (year != null && month != null && day != null) {
        return _validDate(year, month, day);
      }
    }
    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _id.text.trim().isEmpty ||
        _birth.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(certificationRepositoryProvider.future);
      final result = await repo.saveIdentityInfo(
        birthDate: _birth.text.trim(),
        idNumber: _id.text.trim(),
        fullName: _name.text.trim(),
        type: '11',
        cardType: widget.cardType,
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      final flow = await ref.read(productApplicationFlowProvider.future);
      if (mounted) {
        await flow.continueProductDetailFlow(
          context: context,
          productId: widget.productId,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _IdentityBirthdaySheet extends StatefulWidget {
  const _IdentityBirthdaySheet({required this.initialDate});
  final DateTime initialDate;

  @override
  State<_IdentityBirthdaySheet> createState() => _IdentityBirthdaySheetState();
}

class _IdentityBirthdaySheetState extends State<_IdentityBirthdaySheet> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLayout.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: l.px(363) + MediaQuery.viewPaddingOf(context).bottom,
          padding: l
              .edgeInsets(left: 20, right: 20, top: 26, bottom: 20)
              .add(
                EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: l.radius(30).topLeft),
          ),
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  dateOrder: DatePickerDateOrder.dmy,
                  initialDateTime: _date,
                  minimumDate: DateTime(1900),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (value) => _date = value,
                ),
              ),
              SizedBox(
                height: l.px(48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            238,
                            238,
                            238,
                            1,
                          ),
                          foregroundColor: const Color.fromRGBO(
                            153,
                            153,
                            153,
                            1,
                          ),
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(width: l.px(8)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _date),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
