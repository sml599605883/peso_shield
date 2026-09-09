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

  Color _parseColor(String colorHex) {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final statusColor = _parseColor(order.statusColor);

    return Material(
      color: AppColors.white,
      borderRadius: layout.radius(10),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: layout.radius(10),
        child: Padding(
          padding: layout.edgeInsets(
            left: 15,
            right: 15,
            top: 15,
            bottom: 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 20 / 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: layout.edgeInsets(
                      left: 8,
                      right: 8,
                      top: 4,
                      bottom: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: layout.radius(4),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: layout.px(12)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.amountLabel,
                    style: TextStyle(
                      color: AppColors.mutedBlue,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                  SizedBox(width: layout.px(8)),
                  Text(
                    order.amount,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 28 / 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: layout.px(12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.dateLabel}: ${order.date}',
                    style: TextStyle(
                      color: AppColors.mutedBlue,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                  if (order.overdueDays > 0)
                    Text(
                      'Overdue ${order.overdueDays} days',
                      style: TextStyle(
                        color: AppColors.orderAction,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                      ),
                    ),
                ],
              ),
              if (order.buttonText.isNotEmpty) ...[
                SizedBox(height: layout.px(12)),
                SizedBox(
                  width: double.infinity,
                  height: layout.px(44),
                  child: ElevatedButton(
                    onPressed: onButtonTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: layout.radius(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      order.buttonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 18 / 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
