import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/certification_data.dart';
import 'package:peso_shield/pages/account_list_page.dart';

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
}

void _useDesignViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 854);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
