import 'package:flutter/material.dart';

import '../../data/models/certification_data.dart' as model;
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

class PersonalInformationPaydaySelection {
  const PersonalInformationPaydaySelection({
    required this.parent,
    required this.child,
  });

  final model.PersonalInformationOption parent;
  final model.PersonalInformationOption child;

  String get displayValue => '${parent.label}|${child.label}';
  String get submitValue => child.value;
}

Future<PersonalInformationPaydaySelection?> showPersonalInformationPaydaySheet({
  required BuildContext context,
  required List<model.PersonalInformationOption> options,
  String? initialValue,
}) {
  if (options.isEmpty) return Future.value(null);
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<PersonalInformationPaydaySelection>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.personalInformationSelectionBarrier,
    isScrollControlled: true,
    builder: (_) => _PersonalInformationPaydaySheet(
      options: options,
      initialValue: initialValue ?? '',
    ),
  );
}

class _PersonalInformationPaydaySheet extends StatefulWidget {
  const _PersonalInformationPaydaySheet({
    required this.options,
    required this.initialValue,
  });

  final List<model.PersonalInformationOption> options;
  final String initialValue;

  @override
  State<_PersonalInformationPaydaySheet> createState() =>
      _PersonalInformationPaydaySheetState();
}

class _PersonalInformationPaydaySheetState
    extends State<_PersonalInformationPaydaySheet> {
  int _parentIndex = 0;
  model.PersonalInformationOption? _selectedChild;
  bool _showChildren = false;

  @override
  void initState() {
    super.initState();
    // Keep every reopen at the period list, as in the reference app.
    final current = widget.initialValue.trim().toLowerCase();
    for (var index = 0; index < widget.options.length; index++) {
      final parent = widget.options[index];
      final child = parent.children.where((candidate) {
        final display = '${parent.label}|${candidate.label}';
        return candidate.value.toLowerCase() == current ||
            candidate.label.toLowerCase() == current ||
            display.toLowerCase() == current;
      });
      if (child.isNotEmpty) {
        _parentIndex = index;
        _selectedChild = child.first;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final options = _showChildren
        ? widget.options[_parentIndex].children
        : widget.options;
    final rowCount = options.length.clamp(1, 5).toDouble();
    final rowHeight = 69.0;
    final listHeight = rowCount * rowHeight + (rowCount - 1);
    final sheetHeight = listHeight + (_showChildren ? 48 : 0) + 30 + 48 + 20;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        key: const Key('personalInformationPaydaySheet'),
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
                .edgeInsets(left: 20, top: 0, right: 20, bottom: 20)
                .copyWith(bottom: layout.px(20) + bottomInset),
            child: Column(
              children: [
                if (_showChildren)
                  SizedBox(
                    height: layout.px(48),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        key: const Key('personalInformationPaydayBack'),
                        onPressed: () => setState(() => _showChildren = false),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                SizedBox(
                  height: layout.px(listHeight),
                  child: ListView.separated(
                    key: Key(
                      _showChildren
                          ? 'personalInformationPaydayChildren'
                          : 'personalInformationPaydayParents',
                    ),
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Container(
                      margin: layout.edgeInsets(left: 4, right: 5),
                      height: layout.px(1),
                      child: CustomPaint(
                        painter: _PersonalInformationPaydayDashedDividerPainter(
                          color: AppColors.identityUploadDivider,
                          dashWidth: layout.px(4),
                          gapWidth: layout.px(4),
                        ),
                      ),
                    ),
                    itemBuilder: (_, index) {
                      final option = options[index];
                      final selected = _showChildren
                          ? option == _selectedChild
                          : index == _parentIndex && _selectedChild != null;
                      return InkWell(
                        key: Key(
                          _showChildren
                              ? 'personalInformationPaydayChild_$index'
                              : 'personalInformationPaydayParent_$index',
                        ),
                        onTap: () {
                          if (_showChildren) {
                            setState(() => _selectedChild = option);
                          } else if (option.children.isNotEmpty) {
                            setState(() {
                              _parentIndex = index;
                              _selectedChild = null;
                              _showChildren = true;
                            });
                          }
                        },
                        child: SizedBox(
                          height: layout.px(rowHeight),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: layout.edgeInsets(left: 20, right: 40),
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.identityText,
                                    fontFamily: 'Helvetica',
                                    fontSize: layout.px(18),
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  right: layout.px(11),
                                  child: Image.asset(
                                    AppAssets.identityUploadCheckmark,
                                    width: layout.px(20),
                                    height: layout.px(20),
                                    semanticLabel: 'Selected option',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: layout.px(30)),
                SizedBox(
                  width: double.infinity,
                  height: layout.px(48),
                  child: FilledButton(
                    key: const Key('personalInformationPaydayDone'),
                    onPressed: _selectedChild == null
                        ? null
                        : () => Navigator.of(context).pop(
                            PersonalInformationPaydaySelection(
                              parent: widget.options[_parentIndex],
                              child: _selectedChild!,
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      disabledBackgroundColor: AppColors.coral,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: layout.radius(24),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalInformationPaydayDashedDividerPainter extends CustomPainter {
  const _PersonalInformationPaydayDashedDividerPainter({
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
  bool shouldRepaint(
    _PersonalInformationPaydayDashedDividerPainter oldDelegate,
  ) {
    return color != oldDelegate.color ||
        dashWidth != oldDelegate.dashWidth ||
        gapWidth != oldDelegate.gapWidth;
  }
}
