import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:peso_shield/core/ui/toast_helper.dart';
import 'package:peso_shield/data/models/certification_data.dart';
import 'package:peso_shield/pages/account_list_page.dart';
import 'package:peso_shield/theme/app_assets.dart';

void main() {
  const bank = BankAccount(
    id: 'bank-1',
    logoUrl: '',
    available: false,
    bankName: 'BDO',
    accountNumber: '5490163575561234',
    firstName: '',
    middleName: '',
    lastName: '',
    isMain: true,
    type: '8',
    maintenanceMessage: 'The bank is under maintenance. Loans may be delayed. '
        'Please wait or choose another option',
  );
  const wallet = BankAccount(
    id: 'wallet-1',
    logoUrl: '',
    available: true,
    bankName: 'GCash',
    accountNumber: '1234',
    firstName: '',
    middleName: '',
    lastName: '',
    isMain: false,
    type: '9',
    maintenanceMessage: '',
  );

  testWidgets('renders groups and allows maintenance account selection', (
    tester,
  ) async {
    _useDesignViewport(tester);
    AccountListResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<AccountListResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountListPage(
                    groups: [
                      BankAccountGroup(title: 'Bank', accounts: [bank]),
                      BankAccountGroup(title: 'E-wallet', accounts: [wallet]),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('E-wallet'), findsOneWidget);
    expect(find.textContaining('under maintenance'), findsOneWidget);
    expect(find.byKey(const Key('account-list-add')), findsOneWidget);
    expect(find.byKey(const Key('account-list-submit')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-wallet-1')));
    await tester.tap(find.byKey(const Key('account-list-submit')));
    await tester.pumpAndSettle();

    expect(result, isA<AccountListSelection>());
    expect((result as AccountListSelection).bindId, 'wallet-1');
  });

  testWidgets('does not preselect non-main accounts', (tester) async {
    _useDesignViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: AccountListPage(
          groups: [
            BankAccountGroup(title: 'E-wallet', accounts: [wallet]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('account-list-submit'));
    // 没有主卡时不预选（显示未选中图标），但提交按钮保持可点击。
    expect(_iconCount(tester, AppAssets.accountUnselected), 1);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('account-wallet-1')));
    await tester.pump();
    expect(_iconCount(tester, AppAssets.accountSelected), 1);
  });

  testWidgets('warns instead of leaving when submitting without a selection', (
    tester,
  ) async {
    _useDesignViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: const AccountListPage(
          groups: [
            BankAccountGroup(title: 'E-wallet', accounts: [wallet]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account-list-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 未勾选账号时点击提交不离开页面，并给出 toast 提示。
    expect(find.byType(AccountListPage), findsOneWidget);
    expect(find.text('Please select a payment method'), findsOneWidget);

    ToastHelper.cancel();
    await tester.pump(const Duration(seconds: 3));
  });
}

int _iconCount(WidgetTester tester, String asset) => tester
    .widgetList<Image>(find.byType(Image))
    .where(
      (widget) =>
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == asset,
    )
    .length;

void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 854);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
