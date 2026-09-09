import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/pages/home/widgets/loan_process_card.dart';
import 'package:peso_shield/theme/app_assets.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/pages/home/widgets/loan_process_section.dart';

void main() {
  const steps = [
    LoanProcessStep(title: 'Loan amount', amount: '₱ 30,000', active: true),
    LoanProcessStep(title: 'Loan amount', amount: '₱ 40,000', active: false),
    LoanProcessStep(title: 'Loan amount', amount: '₱ 50,000', active: false),
    LoanProcessStep(title: 'Loan amount', amount: '₱ 60,000', active: false),
  ];
  for (final value in <Object?>[
    null,
    [],
    '',
    '[]',
    [null, 1, 'invalid'],
  ]) {
    testWidgets('Empty or invalid grummer $value uses process illustration', (
      tester,
    ) async {
      final product = ProductCard.fromJson({'grummer': value});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoanProcessSection(grummer: product.grummer)),
        ),
      );
      expect(product.grummer, isEmpty);
      expect(find.byKey(const Key('loan-process-card')), findsOneWidget);
      expect(find.byKey(const Key('loan-process-status-card')), findsNothing);
    });
  }

  for (final count in [1, 3, 5]) {
    testWidgets('Renders $count server steps in order with server state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final product = ProductCard.fromJson({
        'grummer': List.generate(
          count,
          (index) => {
            'stalagmitic': '${91 + index} Days',
            'unclogging': '₱${12 + index},345.67',
            'under': index == count - 1 ? 1 : 0,
          },
        ),
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LoanProcessSection(grummer: product.grummer)),
        ),
      );
      expect(find.byKey(const Key('loan-process-status-card')), findsOneWidget);
      expect(find.byKey(const Key('loan-process-card')), findsNothing);
      expect(find.text('Loan amount'), findsNothing);
      expect(find.text('₱ 30,000'), findsNothing);
      double previousLeft = -1;
      for (var index = 0; index < count; index++) {
        expect(find.text('${91 + index} Days'), findsOneWidget);
        expect(find.text('₱${12 + index},345.67'), findsOneWidget);
        final titleLeft = tester.getTopLeft(find.text('${91 + index} Days')).dx;
        expect(titleLeft, greaterThan(previousLeft));
        previousLeft = titleLeft;
        expect(product.grummer[index].active, index == count - 1);
      }
      final locks = tester
          .widgetList<Image>(find.byType(Image))
          .where(
            (image) =>
                image.image is AssetImage &&
                [
                  AppAssets.loanProcessLockActive,
                  AppAssets.loanProcessLockInactive,
                ].contains((image.image as AssetImage).assetName),
          )
          .toList();
      expect(locks.length, count);
      for (var index = 0; index < count; index++) {
        expect(
          (locks[index].image as AssetImage).assetName,
          index == count - 1
              ? AppAssets.loanProcessLockActive
              : AppAssets.loanProcessLockInactive,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('Loan process status fits width $width', (tester) async {
      tester.view.physicalSize = Size(width, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoanProcessCard(steps: steps)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Loan amount'), findsNWidgets(4));
      final card = tester.getRect(
        find.byKey(const Key('loan-process-status-card')),
      );
      expect(card.height, closeTo(98 * width / 375, 0.01));
      final locks = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            [
              AppAssets.loanProcessLockActive,
              AppAssets.loanProcessLockInactive,
            ].contains((widget.image as AssetImage).assetName),
      );
      expect(locks, findsNWidgets(4));
      for (final lock in locks.evaluate()) {
        final bounds = tester.getRect(find.byWidget(lock.widget));
        expect(card.contains(bounds.topLeft), isTrue);
        expect(bounds.top - card.top, closeTo(15 * width / 375, 0.01));
        expect(bounds.center.dy - card.top, closeTo(24.5 * width / 375, 0.01));
        expect(
          bounds.bottom,
          lessThan(tester.getTopLeft(find.text('Loan amount').first).dy),
        );
      }
      for (final amount in ['30,000', '40,000', '50,000', '60,000']) {
        final bounds = tester.getRect(
          find.ancestor(
            of: find.text('₱ $amount'),
            matching: find.byType(FittedBox),
          ),
        );
        expect(bounds.bottom, lessThan(card.bottom));
        expect(bounds.top - card.top, closeTo(58 * width / 375, 0.01));
      }

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(body: LoanProcessCard(steps: steps)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Empty status keeps the original process illustration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoanProcessCard())),
    );
    expect(find.byKey(const Key('loan-process-card')), findsOneWidget);
    expect(find.byKey(const Key('loan-process-status-card')), findsNothing);
  });
}
