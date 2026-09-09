import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../core/navigation/app_route_observer.dart';
import '../core/ui/toast_helper.dart';
import '../data/models/order_data.dart';
import '../providers/credit_orders_provider.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import 'widgets/credit_order_card.dart';

class OrderListPage extends ConsumerStatefulWidget {
  const OrderListPage({super.key, this.initialFilter});
  final OrderFilter? initialFilter;

  @override
  ConsumerState<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends ConsumerState<OrderListPage> with RouteAware {
  final _scrollController = ScrollController();
  final Set<String> _activeActions = {};
  PageRoute<dynamic>? _route;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders(filter: widget.initialFilter);
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
  void didPush() => _syncVisibility(refresh: true);

  @override
  void didPopNext() => _syncVisibility(refresh: true);

  @override
  void didPushNext() => _syncVisibility();

  @override
  void didPop() {}

  void _syncVisibility({bool refresh = false}) {
    if (!refresh || _refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted || !(_route?.isCurrent ?? true)) return;
      unawaited(_loadOrders());
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _loadOrders();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(ref.read(creditOrdersProvider.notifier).loadMore());
    }
  }

  Future<void> _loadOrders({OrderFilter? filter}) async {
    final closeLoading = ToastHelper.showLoading();
    try {
      await ref.read(creditOrdersProvider.notifier).loadOrders(filter: filter);
    } finally {
      closeLoading();
    }
  }

  void _onFilterChanged(OrderFilter filter) {
    unawaited(_loadOrders(filter: filter));
  }

  Future<void> _navigate(OrderItem order, String target) async {
    final id = order.orderNo.isEmpty
        ? '${order.productId}|$target'
        : order.orderNo;
    if (!_activeActions.add(id)) return;
    try {
      if (target.isNotEmpty) {
        await AppNavigator.navigateRawTarget(
          context: context,
          ref: ref,
          target: target,
        );
      } else if (order.productId.isNotEmpty) {
        await AppNavigator.applyProduct(
          context: context,
          ref: ref,
          productId: order.productId,
        );
      }
    } catch (e) {
      if (mounted) ToastHelper.showError(e.toString());
    } finally {
      _activeActions.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final async = ref.watch(creditOrdersProvider);
    final current = async.value ?? const CreditOrdersState();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: layout.edgeInsets(left: 20, right: 14, top: 16),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('orderListBack'),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: layout.px(30),
                      height: layout.px(30),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Loan List',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 24 / 20,
                      ),
                    ),
                  ),
                  SizedBox(width: layout.px(30)),
                ],
              ),
            ),
            Padding(
              padding: layout.edgeInsets(
                left: 20,
                right: 20,
                top: 10,
                bottom: 10,
              ),
              child: Container(
                height: layout.px(40),
                padding: EdgeInsets.all(layout.px(3)),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(238, 238, 238, 1),
                  borderRadius: layout.radius(20),
                ),
                child: Row(
                  children: OrderFilter.values
                      .map(
                        (filter) => Expanded(
                          child: Semantics(
                            selected: filter == current.filter,
                            button: true,
                            child: Material(
                              color: filter == current.filter
                                  ? AppColors.coral
                                  : Colors.transparent,
                              borderRadius: layout.radius(20),
                              child: InkWell(
                                onTap: () => _onFilterChanged(filter),
                                borderRadius: layout.radius(20),
                                child: Center(
                                  child: FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        filter.label,
                                        style: TextStyle(
                                          color: filter == current.filter
                                              ? AppColors.white
                                              : AppColors.identityUnselected,
                                          fontSize: 12,
                                          height: 18 / 12,
                                          fontWeight: filter == current.filter
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
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(child: Text('Failed to load orders')),
                      ),
                    ],
                  ),
                ),
                data: (state) => state.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 420,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    AppAssets.creditEmpty,
                                    width: layout.px(204),
                                    height: layout.px(170),
                                  ),
                                  const SizedBox(height: 19),
                                  const Text('No information available'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          padding: layout.edgeInsets(
                            left: 20,
                            right: 20,
                            bottom: 24,
                          ),
                          itemCount:
                              state.orders.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              SizedBox(height: layout.px(10)),
                          itemBuilder: (_, i) {
                            if (i >= state.orders.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final order = state.orders[i];
                            return CreditOrderCard(
                              order: order,
                              onCardTap: () =>
                                  _navigate(order, order.cardClickUrl),
                              onButtonTap: () =>
                                  _navigate(order, order.buttonClickUrl),
                            );
                          },
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
