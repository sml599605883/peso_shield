import 'package:flutter/material.dart';

import '../../data/models/certification_data.dart' as model;
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

Future<model.PersonalInformationOption?> showPersonalInformationOptionSheet({
  required BuildContext context,
  required List<model.PersonalInformationOption> options,
  String? selectedValue,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<model.PersonalInformationOption>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.personalInformationSelectionBarrier,
    isScrollControlled: true,
    builder: (_) => PersonalInformationOptionSheet(
      options: options,
      selectedValue: selectedValue,
    ),
  );
}

class PersonalInformationOptionSheet extends StatefulWidget {
  const PersonalInformationOptionSheet({
    super.key,
    required this.options,
    required this.selectedValue,
  });

  final List<model.PersonalInformationOption> options;
  final String? selectedValue;

  @override
  State<PersonalInformationOptionSheet> createState() =>
      _PersonalInformationOptionSheetState();
}

class _PersonalInformationOptionSheetState
    extends State<PersonalInformationOptionSheet> {
  late model.PersonalInformationOption? _selectedOption =
      _initialSelectedOption();

  model.PersonalInformationOption? _initialSelectedOption() {
    for (final option in widget.options) {
      if (option.value == widget.selectedValue) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final visibleOptionCount = widget.options.length > 5
        ? 5
        : widget.options.length;
    final optionAreaHeight =
        widget.options
            .take(visibleOptionCount)
            .fold<double>(0, (height, _) => height + 69) +
        (visibleOptionCount > 0 ? visibleOptionCount - 1 : 0);
    final sheetHeight = 18 + optionAreaHeight + 30 + 48 + 20;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        key: const Key('personalInformationSelectionSurface'),
        width: double.infinity,
        height: layout.px(sheetHeight) + bottomInset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(layout.px(30)),
            ),
          ),
          child: Padding(
            padding: layout
                .edgeInsets(left: 20, top: 18, right: 20, bottom: 20)
                .copyWith(bottom: layout.px(20) + bottomInset),
            child: Column(
              children: [
                SizedBox(
                  height: layout.px(optionAreaHeight),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.options.length,
                    separatorBuilder: (_, _) => Container(
                      margin: layout.edgeInsets(left: 4, right: 5),
                      height: layout.px(1),
                      child: CustomPaint(
                        painter: _PersonalInformationDashedDividerPainter(
                          color: AppColors.identityUploadDivider,
                          dashWidth: layout.px(4),
                          gapWidth: layout.px(4),
                        ),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return _PersonalInformationOptionRow(
                        option: option,
                        selected: option == _selectedOption,
                        onTap: () => setState(() => _selectedOption = option),
                      );
                    },
                  ),
                ),
                SizedBox(height: layout.px(30)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: layout.px(167),
                      height: layout.px(48),
                      child: _PersonalInformationDialogButton(
                        label: 'Cancel',
                        backgroundColor:
                            AppColors.personalInformationCancelButton,
                        foregroundColor:
                            AppColors.personalInformationCancelText,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(
                      width: layout.px(158),
                      height: layout.px(48),
                      child: _PersonalInformationDialogButton(
                        label: 'Done',
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                        emphasized: true,
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedOption),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalInformationDashedDividerPainter extends CustomPainter {
  const _PersonalInformationDashedDividerPainter({
    required this.color,
    required this.dashWidth,
    required this.gapWidth,
  });

  final Color color;
  final double dashWidth;
  final double gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.square;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_PersonalInformationDashedDividerPainter oldDelegate) {
    return color != oldDelegate.color ||
        dashWidth != oldDelegate.dashWidth ||
        gapWidth != oldDelegate.gapWidth;
  }
}

class _PersonalInformationDialogButton extends StatelessWidget {
  const _PersonalInformationDialogButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.px(24)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: emphasized ? 'Helvetica-Bold' : 'Helvetica',
          fontSize: layout.px(18),
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
          height: 22 / 18,
        ),
      ),
    );
  }
}

class _PersonalInformationOptionRow extends StatelessWidget {
  const _PersonalInformationOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final model.PersonalInformationOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(69),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: layout.edgeInsets(left: 4, right: 11),
          child: Row(
            children: [
              if (option.logoUrl.isNotEmpty) ...[
                Container(
                  width: layout.px(30),
                  height: layout.px(30),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.personalInformationOptionLogoBorder,
                    ),
                    borderRadius: layout.radius(8),
                  ),
                  child: ClipRRect(
                    borderRadius: layout.radius(7),
                    child: Image.network(
                      option.logoUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                SizedBox(width: layout.px(32)),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.identityText,
                        fontFamily: 'Helvetica',
                        fontSize: layout.px(18),
                        fontWeight: FontWeight.normal,
                        height: 22 / 18,
                      ),
                    ),
                    if (option.showsHint)
                      SizedBox(
                        height: layout.px(20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            option.hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.personalInformationOptionHint,
                              fontFamily: 'Helvetica',
                              fontSize: layout.px(10),
                              fontWeight: FontWeight.normal,
                              height: 20 / 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Image.asset(
                  AppAssets.identityUploadCheckmark,
                  width: layout.px(20),
                  height: layout.px(20),
                  semanticLabel: 'Selected option',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
