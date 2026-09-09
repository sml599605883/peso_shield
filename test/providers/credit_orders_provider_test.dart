import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/providers/credit_orders_provider.dart';

void main() {
  test('CreditOrdersState initial state', () {
    const state = CreditOrdersState();
    
    expect(state.orders, isEmpty);
    expect(state.filter, OrderFilter.all);
    expect(state.currentPage, 1);
    expect(state.totalPages, 1);
    expect(state.isLoadingMore, false);
    expect(state.hasMore, false);
    expect(state.isEmpty, true);
  });

  test('OrderFilter enum values', () {
    expect(OrderFilter.all.label, 'All order');
    expect(OrderFilter.outstanding.label, 'Outstanding');
    expect(OrderFilter.overdue.label, 'Overdue');
    expect(OrderFilter.settled.label, 'Settled');
  });

  test('CreditOrdersState copyWith', () {
    const initial = CreditOrdersState();
    final updated = initial.copyWith(
      currentPage: 2,
      totalPages: 5,
      filter: OrderFilter.overdue,
    );
    
    expect(updated.currentPage, 2);
    expect(updated.totalPages, 5);
    expect(updated.filter, OrderFilter.overdue);
    expect(updated.hasMore, true);
  });
}
