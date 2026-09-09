import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/order_data.dart';
import 'package:peso_shield/pages/widgets/credit_order_card.dart';
import 'package:peso_shield/theme/app_colors.dart';

void main() {
  test('parses Peso Shield order status and product logo fields', () {
    final order = OrderItem.fromJson({
      'crampfishes': 'https://example.com/logo.png',
      'uncloud': 180,
    });

    expect(order.productLogo, 'https://example.com/logo.png');
    expect(order.statusCode, 180);
    expect(order.usesOverdueStyle, isTrue);
    expect(order.usesOutstandingStyle, isFalse);
  });

  testWidgets('renders 174, 180, and default card styles', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _card(_order(174, status: 'Outstanding')),
              _card(_order(180, status: 'Overdue')),
              _card(_order(200, status: 'Settled', button: 'Details')),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('creditOrderCard-174'))),
      const Size(335, 147),
    );
    expect(_gradient(tester, 'creditOrderHeader-174').colors, const [
      AppColors.orderWarningTop,
      AppColors.orderWarningBottom,
    ]);
    expect(_gradient(tester, 'creditOrderHeader-180').colors, const [
      AppColors.orderWarningTop,
      AppColors.orderWarningBottom,
    ]);
    expect(_gradient(tester, 'creditOrderHeader-200').colors, const [
      AppColors.recommendationTop,
      AppColors.recommendationBottom,
    ]);
    expect(_textColor(tester, 'creditOrderAction-174'), AppColors.coral);
    expect(_textColor(tester, 'creditOrderAction-180'), AppColors.orderAction);
    expect(_textColor(tester, 'creditOrderAction-200'), AppColors.black);
    expect(_textColor(tester, 'creditOrderDate-180'), AppColors.orderAction);
    expect(_textColor(tester, 'creditOrderDate-174'), AppColors.black);
  });

  testWidgets('limits a long status label to 100 logical pixels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CreditOrderCard(
              order: _order(
                200,
                status: 'A very long status label that should be clipped',
              ),
              onCardTap: () {},
              onButtonTap: () {},
            ),
          ),
        ),
      ),
    );

    final status = tester.widget<ConstrainedBox>(
      find.byKey(const Key('creditOrderStatus-200')),
    );
    expect(status.constraints.maxWidth, 100);
  });

  testWidgets('routes the text action separately from the card', (
    tester,
  ) async {
    var cardTaps = 0;
    var buttonTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreditOrderCard(
            order: _order(180, status: 'Overdue'),
            onCardTap: () => cardTaps++,
            onButtonTap: () => buttonTaps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('creditOrderAction-180')));
    await tester.pump();

    expect(buttonTaps, 1);
    expect(cardTaps, 0);
  });

  testWidgets('fits a narrow screen with enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CreditOrderCard(
                order: _order(180, status: 'Overdue'),
                onCardTap: () {},
                onButtonTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Widget _card(OrderItem order) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: CreditOrderCard(order: order, onCardTap: () {}, onButtonTap: () {}),
);

OrderItem _order(
  int statusCode, {
  required String status,
  String button = 'Repay Now',
}) {
  return OrderItem(
    orderNo: 'ORDER-$statusCode',
    productName: 'App Name',
    productLogo: '',
    statusText: status,
    statusCode: statusCode,
    statusColor: '',
    amount: '₱ 20,000',
    amountLabel: 'Available up to',
    buttonText: button,
    detailUrl: '',
    dateLabel: 'Due Date',
    date: '2026/05/13',
    overdueDays: statusCode == 180 ? 3 : 0,
    cardClickUrl: '/order/detail',
    buttonClickUrl: '/repayment-detail',
    supportEarlyRepay: false,
    earlyRepayTip: '',
    earlyRepayUrl: '',
  );
}

LinearGradient _gradient(WidgetTester tester, String key) {
  final container = tester.widget<Container>(find.byKey(ValueKey(key)));
  return (container.decoration! as BoxDecoration).gradient! as LinearGradient;
}

Color? _textColor(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(ValueKey(key))).style?.color;
}
