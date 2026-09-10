import 'package:flutter/material.dart';
import 'package:peso_shield/theme/layout_adapter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/ui/toast_helper.dart';
import '../../data/models/home_popup_data.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';

class HomePopup {
  static bool _showing = false;

  static Future<void> show(HomePopupData data) async {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null || _showing || !data.shouldShow) return;
    _showing = true;
    try {
      final open = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.dialogBarrier,
        barrierDismissible: true,
        builder: (context) => data.type == HomePopupType.appUpgrade
            ? Material(
                type: MaterialType.transparency,
                child: _UpgradePopup(data: data),
              )
            : data.type == HomePopupType.marketing
                ? GestureDetector(
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 23),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            data.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textPrimary,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
            : AlertDialog(
                scrollable: true,
                title: const Text('Membership Upgrade'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.levelImageUrl.isNotEmpty)
                      Image.network(
                        data.levelImageUrl,
                        width: 64,
                        height: 64,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    Text(data.currentLevel),
                    if (data.previousLevel.isNotEmpty)
                      Text('Previous: ${data.previousLevel}'),
                    for (final benefit in data.benefits)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(benefit),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Close'),
                  ),
                ],
              ),
      );
      if (open != true || data.targetUrl.isEmpty) return;
      final uri = Uri.tryParse(data.targetUrl);
      if (uri == null || !uri.hasScheme) {
        ToastHelper.showError('Invalid link');
        return;
      }
      if (data.type == HomePopupType.appUpgrade) {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      }
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        await AppNavigator.toWebView(url: data.targetUrl);
      } else {
        ToastHelper.showError('Unable to open link');
      }
    } catch (_) {
      ToastHelper.showError('Unable to open link');
    } finally {
      _showing = false;
    }
  }
}

class _UpgradePopup extends StatelessWidget {
  const _UpgradePopup({required this.data});

  final HomePopupData data;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final popupWidth = (screenWidth - 64).clamp(280.0, 343.0);
    final backgroundHeight = popupWidth * (927 / 933);
    final layout = AppLayout.of(context);

    return Center(
      child: Container(
        padding: layout.edgeInsets(left: 26, right: 26, top: 46, bottom: 17),
        width: popupWidth,
        height: backgroundHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.accountDialogPanel),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: layout.px(24),
                child: Text(
                  'New version released',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: layout.px(20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.px(35)),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Text(
                  data.version,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.px(14)),
            SizedBox(
              width: double.infinity,
              child: Text(
                data.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 21 / 15,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(
                        color: AppColors.white,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
