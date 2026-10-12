import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/pages/home/widgets/loan_terms.dart';
import 'package:peso_shield/theme/app_colors.dart';

void main() {
  Future<void> pumpTerms(WidgetTester tester, Widget terms) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 267, height: 69, child: terms)),
        ),
      ),
    );
  }

  testWidgets('renders delivered loan term rows as badge value plus unit', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        termLabel: 'Loan Term',
        rateLabel: 'Low Interest',
        rows: [
          LoanTermRow(label: 'Loan Term', value: '3', unit: 'Terms'),
          LoanTermRow(label: 'Loan Term', value: '4', unit: 'Terms'),
        ],
      ),
    );

    expect(find.text('Loan Term'), findsNWidgets(2));
    expect(find.text('Terms'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('91-180 Days'), findsNothing);
    expect(find.text('Low Interest'), findsNothing);

    final badge = find
        .ancestor(of: find.text('3'), matching: find.byType(Container))
        .first;
    final decoration =
        tester.widget<Container>(badge).decoration! as BoxDecoration;
    expect(decoration.color, AppColors.loanTermBadge);
    expect(decoration.borderRadius, BorderRadius.circular(6));
    expect(tester.getSize(badge).height, 27);
    expect(tester.getSize(badge).width, greaterThanOrEqualTo(28));

    final value = tester.widget<Text>(find.text('3')).style!;
    expect(value.color, AppColors.white);
    expect(value.fontSize, 22);
    expect(value.fontWeight, FontWeight.w700);

    final unit = tester.widget<Text>(find.text('Terms').first).style!;
    expect(unit.color, AppColors.black);
    expect(unit.fontSize, 16);
    expect(unit.fontWeight, FontWeight.w700);
  });

  test('parses delivered loan term row fields', () {
    final row = LoanTermRow.fromJson({
      'strove': 'Loan Term',
      'discommoding': '3',
      'amoebaean': 'Terms',
    });

    expect(row.label, 'Loan Term');
    expect(row.value, '3');
    expect(row.unit, 'Terms');
  });

  testWidgets('keeps plain loan terms when no rows are delivered', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        termLabel: 'Loan Term',
        rateLabel: 'Low Interest',
      ),
    );

    expect(find.text('Loan Term'), findsOneWidget);
    expect(find.text('91-180 Days'), findsOneWidget);
    expect(find.text('Low Interest'), findsOneWidget);
    expect(find.text('≤ 0.05% / Day'), findsOneWidget);
  });
}
