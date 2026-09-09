import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/ui/toast_helper.dart';
import '../../data/models/home_popup_data.dart';
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
        builder: (context) => data.type == HomePopupType.marketing
            ? Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, true),
                        child: Image.network(
                          data.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              )
            : AlertDialog(
                scrollable: true,
                title: Text(
                  data.type == HomePopupType.appUpgrade
                      ? 'App Update'
                      : 'Membership Upgrade',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.type == HomePopupType.appUpgrade) ...[
                      if (data.version.isNotEmpty) Text(data.version),
                      if (data.message.isNotEmpty) Text(data.message),
                    ] else ...[
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
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Close'),
                  ),
                  if (data.type == HomePopupType.appUpgrade &&
                      data.targetUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Update Now'),
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
