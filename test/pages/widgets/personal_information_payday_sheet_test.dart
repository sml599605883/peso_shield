import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/certification_data.dart';
import 'package:peso_shield/pages/widgets/personal_information_payday_sheet.dart';

void main() {
  testWidgets('selects a payday child and returns display and submit values', (
    tester,
  ) async {
    PersonalInformationPaydaySelection? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPersonalInformationPaydaySheet(
                context: context,
                options: const [
                  PersonalInformationOption(
                    label: 'Daily',
                    value: 'daily',
                    children: [
                      PersonalInformationOption(label: 'Every day', value: '1'),
                    ],
                  ),
                  PersonalInformationOption(
                    label: 'Once a Month',
                    value: 'monthly',
                    children: [
                      PersonalInformationOption(label: '1', value: '11'),
                    ],
                  ),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('personalInformationPaydayParents')),
      findsOneWidget,
    );

    await tester.tap(find.text('Once a Month'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('personalInformationPaydayChildren')),
      findsOneWidget,
    );
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('personalInformationPaydayDone')));
    await tester.pumpAndSettle();

    expect(result?.displayValue, 'Once a Month|1');
    expect(result?.submitValue, '11');
  });

  testWidgets('back returns to the period list without closing the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPersonalInformationPaydaySheet(
              context: context,
              options: const [
                PersonalInformationOption(
                  label: 'Once a Month',
                  value: 'monthly',
                  children: [
                    PersonalInformationOption(label: '1', value: '11'),
                  ],
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Once a Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('personalInformationPaydayBack')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('personalInformationPaydayParents')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('personalInformationPaydaySheet')),
      findsOneWidget,
    );
  });
}
