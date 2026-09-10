import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../core/navigation/app_route_observer.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/order_data.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../providers/credit_orders_provider.dart';
import 'widgets/credit_order_card.dart';

class CreditPage extends ConsumerStatefulWidget {
  const CreditPage({super.key, this.isActive = true});

  final bool isActive;

  @override
  ConsumerState<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends ConsumerState<CreditPage> with RouteAware {
  final _scrollController = ScrollController();
  PageRoute<dynamic>? _route;
  bool _refreshScheduled = false;
  final Set<String> _activeActionIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load orders on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creditOrdersProvider.notifier).loadOrders();
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
  void didUpdateWidget(CreditPage oldWidget) {
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
  void didPop() {}

  void _syncVisibility({bool refresh = false}) {
    if (!refresh || _refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      final visible = widget.isActive && (_route?.isCurrent ?? true);
      if (visible) {
        unawaited(ref.read(creditOrdersProvider.notifier).loadOrders());
      }
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(creditOrdersProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    final closeLoading = ToastHelper.showLoading();
    try {
      await ref.read(creditOrdersProvider.notifier).loadOrders();
    } finally {
      closeLoading();
    }
  }

  void _onFilterChanged(OrderFilter filter) {
    ref.read(creditOrdersProvider.notifier).loadOrders(filter: filter);
  }

  Future<void> _handleCardTap(OrderItem order) async {
    await _handleOrderNavigation(order, target: order.cardClickUrl);
  }

  Future<void> _handleButtonTap(OrderItem order) async {
    await _handleOrderNavigation(order, target: order.buttonClickUrl);
  }

  Future<void> _handleOrderNavigation(
    OrderItem order, {
    required String target,
  }) async {
    final actionId = order.orderNo.isNotEmpty
        ? order.orderNo
        : '${order.productId}|$target';

    // Prevent duplicate actions
    if (!_activeActionIds.add(actionId)) return;

    try {
      // Priority 1: Navigate to target URL if provided
      if (target.isNotEmpty) {
        await _runNavigation(
          () => AppNavigator.navigateRawTarget(
            context: context,
            ref: ref,
            target: target,
          ),
        );
        return;
      }

      // Priority 2: If no target but has productId, start product application
      if (order.productId.isNotEmpty) {
        await _runNavigation(
          () => AppNavigator.applyProduct(
            context: context,
            ref: ref,
            productId: order.productId,
          ),
        );
      }
    } finally {
      _activeActionIds.remove(actionId);
    }
  }

  Future<void> _runNavigation(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ToastHelper.showError(error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final ordersAsync = ref.watch(creditOrdersProvider);
    final ordersState = ordersAsync.value ?? const CreditOrdersState();

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
          child: ordersAsync.when(
            data: (state) => RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: layout.edgeInsets(left: 20, right: 20),
                      child: Column(
                        children: [
                          SizedBox(height: layout.px(19)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Hi!  Welcome',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: layout.px(22),
                                    fontWeight: FontWeight.w700,
                                    height: 26 / 22,
                                  ),
                                ),
                              ),
                              Image.asset(
                                AppAssets.notification,
                                width: layout.px(32),
                                height: layout.px(32),
                                semanticLabel: 'Messages',
                              ),
                            ],
                          ),
                          SizedBox(height: layout.px(10)),
                          Container(
                            height: layout.px(40),
                            padding: EdgeInsets.all(layout.px(3)),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: layout.radius(20),
                            ),
                            child: Row(
                              children: OrderFilter.values.map((filter) {
                                final selected = filter == ordersState.filter;
                                return Expanded(
                                  flex: filter == OrderFilter.outstanding
                                      ? 113
                                      : 74,
                                  child: Semantics(
                                    selected: selected,
                                    button: true,
                                    child: Material(
                                      color: selected
                                          ? AppColors.coral
                                          : AppColors.white,
                                      borderRadius: layout.radius(20),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => _onFilterChanged(filter),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                filter.label,
                                                style: TextStyle(
                                                  color: selected
                                                      ? AppColors.white
                                                      : AppColors
                                                            .identityUnselected,
                                                  fontSize: 12,
                                                  height: 18 / 12,
                                                  fontWeight: selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: layout.px(15)),
                        ],
                      ),
                    ),
                  ),
                  if (state.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(layout),
                    )
                  else
                    SliverPadding(
                      padding: layout.edgeInsets(
                        left: 20,
                        right: 20,
                        bottom: 24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= state.orders.length) {
                              return Center(
                                child: Padding(
                                  padding: layout.edgeInsets(
                                    top: 16,
                                    bottom: 16,
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
                              );
                            }
                            final order = state.orders[index];
                            return Padding(
                              padding: index > 0
                                  ? EdgeInsets.only(top: layout.px(12))
                                  : EdgeInsets.zero,
                              child: CreditOrderCard(
                                order: order,
                                onCardTap: () => _handleCardTap(order),
                                onButtonTap: () => _handleButtonTap(order),
                              ),
                            );
                          },
                          childCount:
                              state.orders.length +
                              (state.isLoadingMore ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: layout.px(64),
                          color: AppColors.mutedBlue,
                        ),
                        SizedBox(height: layout.px(16)),
                        Text(
                          'Failed to load orders',
                          style: TextStyle(
                            color: AppColors.mutedBlue,
                            fontSize: 14,
                            height: 18 / 14,
                          ),
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

  Widget _buildEmptyState(AppLayout layout) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: Padding(
          padding: layout.edgeInsets(left: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.creditEmpty,
                width: layout.px(204),
                height: layout.px(170),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              SizedBox(height: layout.px(19)),
              const Text(
                'No information available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14,
                  height: 18 / 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
