import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

/// Reusable labeled input used by the personal, work, and bank information
/// forms. Read-only fields remain tappable for a picker and never request the
/// keyboard.
class PersonalInformationInputField extends StatelessWidget {
  const PersonalInformationInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.showTrailingArrow = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool readOnly;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool showTrailingArrow;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.personalInformationLabel,
            fontFamily: 'Helvetica',
            fontSize: layout.px(14),
          ),
        ),
        SizedBox(height: layout.px(7)),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.loginHint,
              fontSize: layout.px(14),
            ),
            suffixIcon: showTrailingArrow
                ? Padding(
                    padding: layout.edgeInsets(top: 14, bottom: 14, right: 14),
                    child: Image.asset(
                      AppAssets.personalInformationBack,
                      width: layout.px(16),
                      height: layout.px(11),
                      fit: BoxFit.contain,
                    ),
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
}
