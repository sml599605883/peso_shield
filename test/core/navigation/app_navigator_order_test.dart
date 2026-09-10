import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';

void main() {

  group('OrderFilter segregate mapping', () {
    test('all filter has segregate value 4', () {
      expect(OrderFilter.all.segregateValue, '4');
    });

    test('outstanding filter has segregate value 7', () {
      expect(OrderFilter.outstanding.segregateValue, '7');
    });

    test('overdue filter has segregate value 6', () {
      expect(OrderFilter.overdue.segregateValue, '6');
    });

    test('settled filter has segregate value 5', () {
      expect(OrderFilter.settled.segregateValue, '5');
    });

    test('finds filter by segregate value', () {
      expect(
        OrderFilter.values.firstWhere((f) => f.segregateValue == '4'),
        OrderFilter.all,
      );
      expect(
        OrderFilter.values.firstWhere((f) => f.segregateValue == '7'),
        OrderFilter.outstanding,
      );
      expect(
        OrderFilter.values.firstWhere((f) => f.segregateValue == '6'),
        OrderFilter.overdue,
      );
      expect(
        OrderFilter.values.firstWhere((f) => f.segregateValue == '5'),
        OrderFilter.settled,
      );
    });
  });
}
