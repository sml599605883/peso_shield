import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../core/navigation/app_route_observer.dart';
import '../data/models/home_data.dart';
import '../data/models/home_modules.dart';
import '../core/ui/toast_helper.dart';
import '../providers/home_order_controller.dart';
import '../providers/repository_provider.dart';
import 'home/home_account_change.dart';
import 'home/widgets/home_order_status.dart';
import 'home/widgets/home_recommendations.dart';
import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import '../providers/home_provider.dart';
import '../providers/home_banner_provider.dart';
import 'home/widgets/home_banner.dart';
import 'home/widgets/widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.grummer = const [], this.isActive = true});

  final List<LoanProcessStep> grummer;
  final bool isActive;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  PageRoute<dynamic>? _route;
  bool _refreshScheduled = false;
  bool _bannerVisible = true;
  late final _orderController = HomeOrderController(
    navigate: _openOrderTarget,
    apply: (id) => _handleApply(context, id),
    retry: (orderNo) async {
      final repository = await ref.read(orderRepositoryProvider.future);
      final response = await repository.retryOriginalAccount(orderNo);
      if (!response.isSuccess) throw StateError(response.message);
      return response.data;
    },
    changeAccount: (item) => changeHomeOrderAccount(
      context: context,
      ref: ref,
      item: item,
      navigate: (target) => _openOrderTarget(target, item),
    ),
    showLoading: ToastHelper.showLoading,
    showError: ToastHelper.showError,
  );

  Future<void> _openOrderTarget(String target, HomeOrderProgress item) async {
    if (!mounted) return;
    await AppNavigator.navigateRawTarget(
      context: context,
      ref: ref,
      target: target,
      productId: item.productId,
      apiRemind: 0,
    );
  }

  void _syncVisibility({bool refresh = false}) {
    final visible = widget.isActive && (_route?.isCurrent ?? true);
    if (_bannerVisible != visible) {
      setState(() => _bannerVisible = visible);
    }
    ref
        .read(homeDataProvider.notifier)
        .setVisible(widget.isActive && (_route?.isCurrent ?? true));
    if (!refresh || _refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      final visible = widget.isActive && (_route?.isCurrent ?? true);
      final notifier = ref.read(homeDataProvider.notifier);
      notifier.setVisible(visible);
      if (visible) unawaited(notifier.refresh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncVisibility(refresh: widget.isActive);
    }
  }

  @override
  void didPush() => _syncVisibility(refresh: true);
  @override
  void didPushNext() => _syncVisibility();
  @override
  void didPopNext() => _syncVisibility(refresh: true);
  @override
  void didPop() => ref.read(homeDataProvider.notifier).setVisible(false);

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _handleApply(BuildContext context, String productId) async {
    await AppNavigator.applyProduct(
      context: context,
      ref: ref,
      productId: productId,
      apiRemind: 0, // 0: 默认
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeDataProvider);
    final banners = home.asData?.value?.banners;
    final progress =
        home.asData?.value?.progressItems ?? const <HomeOrderProgress>[];
    final recommendations =
        home.asData?.value?.recommendations ?? const <HomeRecommendation>[];
    final products = home.asData?.value?.products ?? const [];
    final product = products.isEmpty ? null : products.first;
    final layout = AppLayout.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.homeBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: layout.edgeInsets(bottom: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    child: Column(
                      children: [
                        const HomeHeader(),
                        SizedBox(height: layout.px(5)),
                        Padding(
                          padding: layout.edgeInsets(left: 10, right: 10),
                          child: product == null
                              ? const SizedBox.shrink()
                              : LoanOfferCard(
                                  product: product,
                                  onTap: () =>
                                      _handleApply(context, product.id),
                                ),
                        ),
                        if (banners == null || banners.isNotEmpty)
                          Padding(
                            padding: layout.edgeInsets(left: 20, right: 20),
                            child: HomeBanner(
                              banners: banners,
                              isActive: widget.isActive && _bannerVisible,
                              onTap: (banner) => unawaited(
                                ref
                                    .read(homeBannerControllerProvider)
                                    .open(
                                      banner,
                                      navigate: (target) async {
                                        if (!mounted) return;
                                        await AppNavigator.navigateRawTarget(
                                          context: context,
                                          ref: ref,
                                          target: target,
                                        );
                                      },
                                    ),
                              ),
                            ),
                          ),
                        if (progress.isNotEmpty)
                          HomeOrderStatus(
                            items: progress,
                            isActive: widget.isActive && _bannerVisible,
                            onTap: (item) =>
                                unawaited(_orderController.open(item)),
                            onAction: (item, action) =>
                                unawaited(_orderController.open(item, action)),
                          ),
                        HomeRecommendations(
                          items: recommendations,
                          onApply: (item) =>
                              unawaited(_handleApply(context, item.id)),
                        ),
                        if (progress.isEmpty)
                          LoanProcessSection(
                            grummer: product?.grummer ?? widget.grummer,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
