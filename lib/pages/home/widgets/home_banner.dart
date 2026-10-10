import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/home_data.dart';
import '../../../theme/app_assets.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({
    super.key,
    this.banners,
    required this.onTap,
    this.isActive = true,
  });

  final List<HomeBannerData>? banners;
  final ValueChanged<HomeBannerData> onTap;
  final bool isActive;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> with WidgetsBindingObserver {
  // Start deep into an infinite page range so the carousel can always advance
  // forward (+1) and wrap around via modulo without a backward jump.
  static const int _initialPage = 10000;
  final _controller = PageController(initialPage: _initialPage);
  Timer? _timer;
  int _page = _initialPage;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _syncTimer();
  }

  @override
  void didUpdateWidget(HomeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners?.length != widget.banners?.length) {
      _page = _initialPage;
      if (_controller.hasClients) _controller.jumpToPage(_initialPage);
    }
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    final count = widget.banners?.length ?? 0;
    if (!widget.isActive || !_foreground || count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients ||
          _controller.position.isScrollingNotifier.value) {
        return;
      }
      unawaited(
        _controller.animateToPage(
          _page + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _fallback() => Image.asset(
    AppAssets.instantFundsBanner,
    width: double.infinity,
    fit: BoxFit.contain,
  );

  Widget _item(HomeBannerData banner) => GestureDetector(
    key: ValueKey('home-banner-${banner.id}'),
    behavior: HitTestBehavior.opaque,
    onTap: () => widget.onTap(banner),
    child: banner.imageUrl.isEmpty
        ? _fallback()
        : Image.network(
            banner.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _fallback(),
            errorBuilder: (_, _, _) => _fallback(),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners != null && banners.isEmpty) return const SizedBox.shrink();
    return AspectRatio(
      // Preserve the existing 1005 x 303 design asset's geometry.
      aspectRatio: 1005 / 303,
      child: banners == null
          ? _fallback()
          : banners.length == 1
          ? _item(banners.single)
          : PageView.builder(
              controller: _controller,
              onPageChanged: (page) => _page = page,
              itemBuilder: (_, index) => _item(banners[index % banners.length]),
            ),
    );
  }
}
