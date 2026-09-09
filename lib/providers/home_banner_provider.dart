import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/home_data.dart';
import 'repository_provider.dart';

final homeBannerControllerProvider = Provider(
  (ref) => HomeBannerController(
    isLoggedIn: () {
      final session = ref.read(userSessionProvider);
      return session.isLoggedIn &&
          (session.accessToken?.trim().isNotEmpty ?? false);
    },
    recordClick: (id) async {
      final repository = await ref.read(appRepositoryProvider.future);
      await repository.recordBannerClick(id);
    },
    showError: ToastHelper.showError,
  ),
);

class HomeBannerController {
  HomeBannerController({
    required this.isLoggedIn,
    required this.recordClick,
    required this.showError,
  });

  final bool Function() isLoggedIn;
  final Future<void> Function(String) recordClick;
  final void Function(String) showError;
  bool _opening = false;

  Future<void> open(
    HomeBannerData banner, {
    required Future<void> Function(String) navigate,
  }) async {
    final target = banner.targetUrl.trim();
    if (target.isEmpty || _opening) return;
    _opening = true;
    try {
      try {
        if (isLoggedIn() && banner.id.trim().isNotEmpty) {
          await recordClick(banner.id.trim());
        }
      } catch (_) {
        // Optional analytics must not prevent navigation.
      }
      await navigate(target);
    } catch (_) {
      showError('Unable to open link');
    } finally {
      _opening = false;
    }
  }
}
