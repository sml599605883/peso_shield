import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/data/models/home_modules.dart';
import 'package:peso_shield/pages/home/widgets/home_order_status.dart';
import 'package:peso_shield/pages/home/widgets/home_recommendations.dart';
import 'package:peso_shield/providers/home_order_controller.dart';
import 'package:peso_shield/theme/app_colors.dart';
import 'package:peso_shield/theme/app_assets.dart';

HomeOrderProgress order(int status) => HomeOrderProgress.fromJson({
  'superparasitism': 'order-$status',
  'bombarder': '12',
  'sajou': 'App Name',
  'kaiserin': 'PHP 20,000',
  'smarmiest': 'Loan Amount',
  'guessed': '2026/05/13',
  'airn': 'Due Date',
  'prutoth': status,
  'mycelia': 'https://example.com/order',
  'pincushions': [
    if (status == 6)
      {'bellings': 'retry', 'beatify': 'Retry Original Card', 'souvlakis': 1},
    {
      'bellings': status == 5 || status == 6
          ? 'change'
          : status == 1 || status == 4
          ? 'detail'
          : 'repay',
      'beatify': status == 5 || status == 6
          ? 'Change Account'
          : status == 1 || status == 4
          ? 'Details'
          : 'Repay',
      'souvlakis': 1,
    },
  ],
});

void main() {
  test('parses only project module values and preserves precise amounts', () {
    final data = HomeData.fromJson({
      'applicants': [
        null,
        {
          'bellings': 'Velarizing',
          'geochronologist': [
            {'prutoth': '3', 'desalting': '12345678901234567890.12'},
            null,
          ],
        },
        {
          'bellings': 'RetaughtMazaedium',
          'geochronologist': [
            {
              'ventral': 8,
              'contexts': '12345.67',
              'haunts': 'Continue',
              'exclusivity': -1,
            },
          ],
        },
        {
          'bellings': 'PRODUCT_LIST',
          'geochronologist': [{}],
        },
      ],
    });
    expect(data.progressItems.single.amount, '12,345,678,901,234,567,890.12');
    expect(data.progressItems.single.status, 3);
    expect(data.recommendations.single.id, '8');
    expect(data.recommendations.single.amount, '12,345.67');
    expect(data.recommendations.single.buttonText, 'Continue');
    expect(HomeData.fromJson({}).recommendations, isEmpty);
  });

  test('prefers large card (Deoxy) over small card (MaximalsNatriureses)', () {
    final data = HomeData.fromJson({
      'applicants': [
        {
          'bellings': 'Deoxy',
          'geochronologist': [
            {
              'ventral': 'large-1',
              'reinters': 'Large Card',
              'contexts': 'PHP 50,000',
            },
          ],
        },
        {
          'bellings': 'MaximalsNatriureses',
          'geochronologist': [
            {
              'ventral': 'small-1',
              'reinters': 'Small Card',
              'contexts': 'PHP 10,000',
            },
          ],
        },
      ],
    });
    expect(data.products.length, 1);
    expect(data.products.first.id, 'large-1');
    expect(data.products.first.name, 'Large Card');
  });

  test('uses small card (MaximalsNatriureses) when large card is absent', () {
    final data = HomeData.fromJson({
      'applicants': [
        {
          'bellings': 'MaximalsNatriureses',
          'geochronologist': [
            {
              'ventral': 'small-1',
              'reinters': 'Small Card',
              'contexts': 'PHP 10,000',
            },
          ],
        },
      ],
    });
    expect(data.products.length, 1);
    expect(data.products.first.id, 'small-1');
    expect(data.products.first.name, 'Small Card');
  });

  test('returns empty products when neither card type exists', () {
    final data = HomeData.fromJson({
      'applicants': [
        {
          'bellings': 'SomeOtherType',
          'geochronologist': [{}],
        },
      ],
    });
    expect(data.products, isEmpty);
  });

  test(
    'repay uses card target, retry closes loading, errors release lock',
    () async {
      final events = <String>[];
      var fail = false;
      final controller = HomeOrderController(
        navigate: (url, item) async => events.add(url),
        apply: (id) async => events.add('apply:$id'),
        retry: (id) async {
          events.add('retry:$id');
          if (fail) throw StateError('offline');
          return 'https://example.com/retry';
        },
        changeAccount: (_) async => events.add('change'),
        showLoading: () {
          events.add('loading');
          return () => events.add('dismiss');
        },
        showError: (_) => events.add('error'),
      );
      await controller.open(
        order(2),
        const HomeOrderAction('repay', 'Repay', url: 'https://wrong.example'),
      );
      expect(events, ['https://example.com/order']);
      events.clear();
      await controller.open(order(6), const HomeOrderAction('retry', 'Retry'));
      expect(events, [
        'loading',
        'retry:order-6',
        'dismiss',
        'https://example.com/retry',
      ]);
      events.clear();
      fail = true;
      await controller.open(order(6), const HomeOrderAction('retry', 'Retry'));
      await controller.open(
        order(6),
        const HomeOrderAction('change', 'Change'),
      );
      expect(events, [
        'loading',
        'retry:order-6',
        'dismiss',
        'error',
        'change',
      ]);
    },
  );

  for (final width in [320.0, 375.0, 450.0]) {
    testWidgets('six statuses and recommendations fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      if (const bool.fromEnvironment('HOME_SCREENSHOT')) {
        await tester.runAsync(() async {
          final bytes = await File(
            '/System/Library/Fonts/Helvetica.ttc',
          ).readAsBytes();
          for (final family in ['Helvetica', 'Roboto']) {
            await (FontLoader(
              family,
            )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          }
        });
      }
      var cardTaps = 0;
      var actionTaps = 0;
      var applies = 0;
      final recommendation = HomeRecommendation.fromJson({
        'ventral': '8',
        'reinters': 'App Name',
        'contexts': 'PHP 20,000',
        'corporeally': 'Available up to',
        'weakness': '180 Days',
        'gipsies': '<= 0.5% / Day',
        'haunts': 'Apply Now',
        'exclusivity': -1,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1600),
              textScaler: TextScaler.linear(width == 320 ? 2 : 1),
            ),
            child: Scaffold(
              body: RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                  color: AppColors.paleBlue,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final status in [1, 5, 4, 2, 6, 3])
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: HomeOrderStatusCard(
                              item: order(status),
                              onTap: () => cardTaps++,
                              onAction: (_) => actionTaps++,
                            ),
                          ),
                        HomeRecommendations(
                          items: [recommendation],
                          onApply: (_) => applies++,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final asset in [
          AppAssets.orderBlue,
          AppAssets.orderWarm,
          AppAssets.orderReviewLabel,
          AppAssets.orderFailedLabel,
          AppAssets.orderDisbursingLabel,
          AppAssets.orderRepaymentLabel,
          AppAssets.orderOverdueLabel,
          AppAssets.loanProcessTitle,
        ]) {
          await precacheImage(AssetImage(asset), boundary.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Review in Progress'));
      expect(cardTaps, 1);
      await tester.tap(find.text('Change Account').first);
      expect(actionTaps, 1);
      expect(cardTaps, 1);
      await tester.ensureVisible(find.text('Apply Now'));
      await tester.tap(find.text('Apply Now'));
      expect(applies, 1);
      if (width == 375 && const bool.fromEnvironment('HOME_SCREENSHOT')) {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/peso-home-modules.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

  testWidgets(
    'order paging survives refreshed shorter list and hides empty modules',
    (tester) async {
      var items = [order(1), order(2), order(3)];
      var active = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return HomeOrderStatus(
                  items: items,
                  isActive: active,
                  onTap: (_) {},
                  onAction: (_, _) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Repayment Required'), findsOneWidget);
      update(() => active = false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Repayment Required'), findsOneWidget);
      update(() => items = [order(1)]);
      await tester.pumpAndSettle();
      expect(find.text('Review in Progress'), findsOneWidget);
      update(() => items = []);
      await tester.pumpAndSettle();
      expect(find.text('Order Status'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
