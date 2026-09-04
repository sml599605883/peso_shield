import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/certification_data.dart';
import 'package:peso_shield/pages/widgets/personal_information_address_sheet.dart';

void main() {
  testWidgets('selects documented address levels before Done returns a value', (
    tester,
  ) async {
    String? result;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPersonalInformationAddressSheet(
                context: context,
                nodes: _nodes,
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
      tester.getSize(find.byKey(const Key('personalInformationAddressSheet'))),
      const Size(375, 428),
    );

    await tester.tap(find.text('Region One'));
    await tester.pumpAndSettle();
    expect(find.text('Province One'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Province One'), findsOneWidget);
    await tester.tap(find.text('Province One'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, 'Region One-Province One');
  });

  testWidgets('selects three-level address only after Done at each level', (
    tester,
  ) async {
    String? result;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPersonalInformationAddressSheet(
                context: context,
                nodes: _nodes,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Region One'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Province Two'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('City One'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, 'Region One-Province Two-City One');
  });

  testWidgets('resets the list position when advancing to another level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPersonalInformationAddressSheet(
              context: context,
              nodes: _manyNodes,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Region 100'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Region 100'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Province 0'), findsOneWidget);
    final listPosition = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(listPosition.position.pixels, 0);
  });
}

final _manyNodes = List.generate(
  101,
  (regionIndex) => PersonalAddressNode(
    id: 'r$regionIndex',
    label: 'Region $regionIndex',
    children: List.generate(
      101,
      (provinceIndex) => PersonalAddressNode(
        id: 'r${regionIndex}p$provinceIndex',
        label: 'Province $provinceIndex',
        children: const [],
      ),
    ),
  ),
);

const _nodes = [
  PersonalAddressNode(
    id: 'r1',
    label: 'Region One',
    children: [
      PersonalAddressNode(id: 'p1', label: 'Province One', children: []),
      PersonalAddressNode(
        id: 'p2',
        label: 'Province Two',
        children: [
          PersonalAddressNode(id: 'm1', label: 'City One', children: []),
          PersonalAddressNode(id: 'm2', label: 'City Two', children: []),
        ],
      ),
    ],
  ),
];
