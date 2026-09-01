import 'package:flutter/material.dart';

import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

/// The temporary local choice returned by the upload method dialog.
enum IdentityUploadMethod { photograph, photoAlbum }

/// Bottom-aligned upload method selector from the identity upload flow.
class IdentityUploadMethodDialog extends StatefulWidget {
  const IdentityUploadMethodDialog({super.key});

  @override
  State<IdentityUploadMethodDialog> createState() =>
      _IdentityUploadMethodDialogState();
}

class _IdentityUploadMethodDialogState
    extends State<IdentityUploadMethodDialog> {
  IdentityUploadMethod _selected = IdentityUploadMethod.photograph;

  void _close([IdentityUploadMethod? method]) {
    Navigator.of(context).pop(method);
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(layout.px(30)),
              topRight: Radius.circular(layout.px(30)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: layout.edgeInsets(
                left: 20,
                top: 18,
                right: 20,
                bottom: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MethodRow(
                    label: 'Photograph',
                    asset: AppAssets.identityUploadCamera,
                    selected: _selected == IdentityUploadMethod.photograph,
                    onTap: () => setState(
                      () => _selected = IdentityUploadMethod.photograph,
                    ),
                  ),
                  SizedBox(height: layout.px(17)),
                  SizedBox(
                    width: layout.px(326),
                    height: layout.px(2),
                    child: CustomPaint(
                      painter: _DashedDividerPainter(
                        color: AppColors.identityUploadDivider,
                        dashWidth: layout.px(4),
                        gapWidth: layout.px(4),
                      ),
                    ),
                  ),
                  SizedBox(height: layout.px(19)),
                  _MethodRow(
                    label: 'Photo Album',
                    asset: AppAssets.identityUploadAlbum,
                    selected: _selected == IdentityUploadMethod.photoAlbum,
                    onTap: () => setState(
                      () => _selected = IdentityUploadMethod.photoAlbum,
                    ),
                  ),
                  SizedBox(height: layout.px(28)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: layout.px(167),
                        height: layout.px(48),
                        child: _DialogButton(
                          label: 'Cancel',
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
                          onPressed: _close,
                        ),
                      ),
                      SizedBox(
                        width: layout.px(158),
                        height: layout.px(48),
                        child: _DialogButton(
                          label: 'Done',
                          backgroundColor: AppColors.coral,
                          foregroundColor: AppColors.white,
                          onPressed: () => _close(_selected),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(36),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Image.asset(asset, width: layout.px(36), height: layout.px(36)),
            SizedBox(width: layout.px(32)),
            Text(
              label,
              style: TextStyle(
                color: AppColors.identityText,
                fontFamily: 'Helvetica',
                fontSize: layout.px(18),
                fontWeight: FontWeight.normal,
                height: 22 / 18,
              ),
            ),
            const Spacer(),
            if (selected)
              Padding(
                padding: layout.edgeInsets(right: 3),
                child: Image.asset(
                  AppAssets.identityUploadCheckmark,
                  width: layout.px(20),
                  height: layout.px(20),
                  semanticLabel: 'Selected upload method',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter({
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
      ..strokeWidth = 1
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
  bool shouldRepaint(_DashedDividerPainter oldDelegate) {
    return color != oldDelegate.color ||
        dashWidth != oldDelegate.dashWidth ||
        gapWidth != oldDelegate.gapWidth;
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

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
          fontFamily: label == 'Done' ? 'Helvetica-Bold' : 'Helvetica',
          fontSize: layout.px(18),
          fontWeight: label == 'Done' ? FontWeight.w700 : FontWeight.normal,
          height: 22 / 18,
        ),
      ),
    );
  }
}
