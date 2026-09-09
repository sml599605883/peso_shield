import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/models/home_modules.dart';
import '../../../theme/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'home_module_title.dart';
import 'home_product_logo.dart';

class HomeOrderStatus extends StatefulWidget {
  const HomeOrderStatus({
    super.key,
    required this.items,
    required this.onTap,
    required this.onAction,
    this.isActive = true,
  });
  final List<HomeOrderProgress> items;
  final ValueChanged<HomeOrderProgress> onTap;
  final void Function(HomeOrderProgress, HomeOrderAction) onAction;
  final bool isActive;
  @override
  State<HomeOrderStatus> createState() => _HomeOrderStatusState();
}

class _HomeOrderStatusState extends State<HomeOrderStatus>
    with WidgetsBindingObserver {
  int _page = 0;
  final _controller = PageController();
  Timer? _timer;
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

  void _syncTimer() {
    _timer?.cancel();
    if (!widget.isActive || !_foreground || widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients ||
          _controller.position.isScrollingNotifier.value) {
        return;
      }
      unawaited(
        _controller.animateToPage(
          (_page + 1) % widget.items.length,
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

  @override
  void didUpdateWidget(HomeOrderStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _page = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
    _syncTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final layout = AppLayout.of(context);
    return Padding(
      padding: layout.edgeInsets(top: 16, left: 20, right: 20),
      child: Column(
        children: [
          const HomeModuleTitle(title: 'Order Status', width: 124),
          SizedBox(
            height: layout.px(162),
            child: PageView.builder(
              controller: _controller,
              key: ValueKey('order-pages-${widget.items.length}'),
              itemCount: widget.items.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (_, index) => HomeOrderStatusCard(
                item: widget.items[index],
                onTap: () => widget.onTap(widget.items[index]),
                onAction: (action) =>
                    widget.onAction(widget.items[index], action),
              ),
            ),
          ),
          if (widget.items.length > 1)
            Padding(
              padding: layout.edgeInsets(top: 10),
              child: Wrap(
                spacing: layout.px(5),
                runSpacing: layout.px(4),
                alignment: WrapAlignment.center,
                children: [
                  for (var index = 0; index < widget.items.length; index++)
                    Container(
                      width: layout.px(index == _page ? 28 : 12),
                      height: layout.px(4),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? AppColors.homePageIndicator
                            : AppColors.white,
                        borderRadius: layout.radius(2),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class HomeOrderStatusCard extends StatelessWidget {
  const HomeOrderStatusCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAction,
  });
  final HomeOrderProgress item;
  final VoidCallback onTap;
  final ValueChanged<HomeOrderAction> onAction;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final (labelAsset, labelWidth) = switch (item.status) {
      1 => (AppAssets.orderReviewLabel, 179),
      4 => (AppAssets.orderDisbursingLabel, 167),
      2 => (AppAssets.orderRepaymentLabel, 190),
      3 => (AppAssets.orderOverdueLabel, 139),
      _ => (AppAssets.orderFailedLabel, 141),
    };
    final actions = item.displayActions;
    return GestureDetector(
      key: ValueKey('order-status-${item.orderNo}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: layout.px(162),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              item.isBlue ? AppAssets.orderBlue : AppAssets.orderWarm,
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: layout.px(106),
              top: layout.px(10),
              width: layout.px(labelWidth),
              height: layout.px(30),
              child: Container(
                padding: layout.edgeInsets(left: 38, right: 10),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(labelAsset),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: _text(item.label, 14, AppColors.white, bold: true),
              ),
            ),
            Positioned(
              left: layout.px(15),
              top: layout.px(10),
              width: layout.px(119),
              height: layout.px(30),
              child: Container(
                padding: layout.edgeInsets(left: 5, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: layout.radius(22),
                ),
                child: Row(
                  children: [
                    HomeProductLogo(url: item.logo, size: layout.px(22)),
                    SizedBox(width: layout.px(5)),
                    Expanded(
                      child: _text(item.name, 16, AppColors.black, bold: true),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: layout.px(15),
              right: layout.px(15),
              top: layout.px(50),
              height: layout.px(63),
              child: Container(
                padding: layout.edgeInsets(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orderPanel,
                  borderRadius: layout.radius(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _value(
                        item.amount,
                        item.amountLabel,
                        AppColors.black,
                      ),
                    ),
                    SizedBox(width: layout.px(16)),
                    Expanded(
                      child: _value(
                        item.date,
                        item.dateLabel,
                        item.status == 3
                            ? AppColors.orderAction
                            : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: layout.px(123),
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.white)),
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0)
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppColors.white,
                        ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          key: ValueKey('order-action-${actions[index].type}'),
                          onTap: () => onAction(actions[index]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _text(
                                    actions[index].label,
                                    16,
                                    item.isBlue ||
                                            actions[index].type == 'retry'
                                        ? AppColors.white
                                        : AppColors.orderAction,
                                    bold: true,
                                  ),
                                  if (actions[index].badge.isNotEmpty)
                                    _text(
                                      actions[index].badge,
                                      10,
                                      AppColors.orderAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _value(String value, String label, Color color) => Column(
    children: [
      Expanded(flex: 3, child: _text(value, 20, color, bold: true)),
      const SizedBox(height: 4),
      Expanded(flex: 2, child: _text(label, 12, AppColors.white)),
    ],
  );
  Widget _text(String text, double size, Color color, {bool bold = false}) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Helvetica',
            fontSize: size,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      );
}
