import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/home_data.dart';
import 'package:peso_shield/pages/home/widgets/loan_terms.dart';
import 'package:peso_shield/theme/app_colors.dart';

void main() {
  Future<void> pumpTerms(
    WidgetTester tester,
    Widget terms, {
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(child: SizedBox(width: 267, height: 69, child: terms)),
        ),
      ),
    );
  }

  RenderParagraph labelParagraph(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  testWidgets('renders delivered loan term rows as badge value plus label', (
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
          LoanTermRow(label: 'Terms', value: '3'),
          LoanTermRow(label: 'Terms', value: '4'),
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
    expect(unit.fontWeight, FontWeight.w700);
    expect(unit.fontSize, greaterThanOrEqualTo(10));
    expect(unit.fontSize, lessThanOrEqualTo(16));
  });

  testWidgets('keeps the label at its base size when the width allows', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        rows: [LoanTermRow(label: 'Terms', value: '3')],
      ),
    );

    expect(tester.widget<Text>(find.text('Terms')).style!.fontSize, 16);
    expect(labelParagraph(tester, 'Terms').didExceedMaxLines, isFalse);
  });

  testWidgets('shrinks the label instead of truncating with two rows', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        rows: [
          LoanTermRow(label: 'Terms', value: '3'),
          LoanTermRow(label: 'Terms', value: '4'),
        ],
      ),
    );

    for (final element in find.text('Terms').evaluate()) {
      final style = (element.widget as Text).style!;
      expect(
        (element.renderObject! as RenderParagraph).didExceedMaxLines,
        isFalse,
      );
      expect(style.fontSize, lessThan(16));
      expect(style.fontSize, greaterThanOrEqualTo(10));
    }
  });

  testWidgets('falls back to an ellipsis once the label hits 10pt', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        rows: [
          LoanTermRow(label: 'Installment Terms', value: '3'),
          LoanTermRow(label: 'Installment Terms', value: '4'),
        ],
      ),
    );

    for (final element in find.text('Installment Terms').evaluate()) {
      final style = (element.widget as Text).style!;
      expect(style.fontSize, 10);
      expect(
        (element.renderObject! as RenderParagraph).didExceedMaxLines,
        isTrue,
      );
    }
  });

  test('parses delivered loan term row fields', () {
    final row = LoanTermRow.fromJson({
      'strove': 'Loan Term',
      'discommoding': '3',
    });

    expect(row.label, 'Loan Term');
    expect(row.value, '3');
  });

  testWidgets('clamps oversized system text inside the fixed row height', (
    tester,
  ) async {
    await pumpTerms(
      tester,
      const LoanTerms(
        loanTerm: '91-180 Days',
        interestRate: '≤ 0.05% / Day',
        rows: [
          LoanTermRow(label: 'Terms', value: '3'),
          LoanTermRow(label: 'Terms', value: '4'),
        ],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Terms'), findsNWidgets(2));
  });

  testWidgets('clamps oversized system text without term rows too', (
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
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Low Interest'), findsOneWidget);
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
