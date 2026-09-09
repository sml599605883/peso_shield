import 'package:flutter/material.dart';

import '../../data/models/order_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

class CreditOrderCard extends StatelessWidget {
  const CreditOrderCard({
    super.key,
    required this.order,
    required this.onCardTap,
    required this.onButtonTap,
  });

  final OrderItem order;
  final VoidCallback onCardTap;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final actionColor = order.usesOutstandingStyle
        ? AppColors.coral
        : order.usesOverdueStyle
        ? AppColors.orderAction
        : AppColors.black;

    return SizedBox(
      key: ValueKey('creditOrderCard-${order.statusCode}'),
      height: layout.px(147),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1,
        child: Material(
          color: AppColors.white,
          elevation: 2,
          shadowColor: AppColors.recommendationShadow,
          borderRadius: layout.radius(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onCardTap,
            child: Stack(
              children: [
                _OrderHeader(order: order, layout: layout),
                Positioned(
                  top: layout.px(37),
                  left: 0,
                  right: 0,
                  height: layout.px(110),
                  child: _OrderDetails(
                    order: order,
                    layout: layout,
                    actionColor: actionColor,
                    onButtonTap: onButtonTap,
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

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, required this.layout});

  final OrderItem order;
  final AppLayout layout;

  @override
  Widget build(BuildContext context) {
    final headerColors = order.usesRepaymentStyle
        ? const [AppColors.orderWarningTop, AppColors.orderWarningBottom]
        : const [AppColors.recommendationTop, AppColors.recommendationBottom];
    final statusColors = order.usesRepaymentStyle
        ? const [AppColors.orderStatusAlertStart, AppColors.orderStatusAlertEnd]
        : const [AppColors.orderStatusBlueStart, AppColors.orderStatusBlueEnd];

    return Container(
      key: ValueKey('creditOrderHeader-${order.statusCode}'),
      height: layout.px(106),
      padding: layout.edgeInsets(left: 15, top: 8, right: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: headerColors,
        ),
        border: Border.all(color: AppColors.white),
        borderRadius: layout.radius(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductLogo(order: order, layout: layout),
          SizedBox(width: layout.px(8)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: layout.px(4)),
              child: Text(
                order.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: layout.px(14),
                  height: 17 / 14,
                ),
              ),
            ),
          ),
          SizedBox(width: layout.px(8)),
          ConstrainedBox(
            key: ValueKey('creditOrderStatus-${order.statusCode}'),
            constraints: BoxConstraints(maxWidth: layout.px(100)),
            child: Container(
              height: layout.px(22),
              padding: EdgeInsets.symmetric(horizontal: layout.px(7)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: statusColors),
                borderRadius: layout.radius(22),
              ),
              child: Text(
                order.statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: layout.px(14),
                  height: 18 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.order, required this.layout});

  final OrderItem order;
  final AppLayout layout;

  @override
  Widget build(BuildContext context) {
    final size = layout.px(30);
    if (order.productLogo.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.avatarGray,
          shape: BoxShape.circle,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        order.productLogo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: AppColors.avatarGray),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({
    required this.order,
    required this.layout,
    required this.actionColor,
    required this.onButtonTap,
  });

  final OrderItem order;
  final AppLayout layout;
  final Color actionColor;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: layout.radius(15),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(height: layout.px(14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.px(27)),
            child: Row(
              children: [
                Expanded(
                  child: _OrderMetric(
                    value: order.amount,
                    label: order.amountLabel,
                    layout: layout,
                  ),
                ),
                SizedBox(width: layout.px(12)),
                Expanded(
                  child: _OrderMetric(
                    valueKey: ValueKey('creditOrderDate-${order.statusCode}'),
                    value: order.date,
                    label: order.dateLabel,
                    layout: layout,
                    valueColor: order.usesOverdueStyle
                        ? AppColors.orderAction
                        : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: layout.px(10)),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.orderInfoBackground,
          ),
          Expanded(
            child: InkWell(
              onTap: order.buttonText.isEmpty ? null : onButtonTap,
              child: Center(
                child: Text(
                  order.buttonText,
                  key: ValueKey('creditOrderAction-${order.statusCode}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: actionColor,
                    fontSize: layout.px(16),
                    fontWeight: FontWeight.w700,
                    height: 22 / 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({
    this.valueKey,
    required this.value,
    required this.label,
    required this.layout,
    this.valueColor = AppColors.black,
  });

  final Key? valueKey;
  final String value;
  final String label;
  final AppLayout layout;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: layout.px(20),
            fontWeight: FontWeight.w700,
            // height: 29 / 24,
          ),
        ),
        SizedBox(height: layout.px(4)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.recommendationCaption,
            fontSize: layout.px(12),
            height: 14 / 12,
          ),
        ),
      ],
    );
  }
}
